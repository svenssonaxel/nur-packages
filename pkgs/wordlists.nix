# Multilingual wordlist generator. Builds dictionaries from Wiktionary SQL dumps,
# aspell, SCOWL (two eras), Debian miscfiles and the Swedish sslug list, then joins
# them per language with a locale-pinned `sort`.
#
# Shape: flake `packages.<name>` must be a single derivation, so this file returns a
# cheap representative build (aspell English) and hangs the full generator API off
# `passthru`. Reach the generator with e.g.
#   nix eval .#wordlists.words-for-language     # the function
#   nix build .#wordlists.passthru.words-en     # words-for-language "en"
# The wiktionary path pulls multi-GB Wikimedia dumps; those derivations only fetch
# when actually built (eval/`nix flake check` never realises them).
#
# Source files are large, so the three Wikimedia dumps are fetched from upstream OR
# a uxu.se mirror fallback (urls=[upstream, mirror]).
{ pkgs }:
let
  inherit (builtins) hasAttr length replaceStrings;
  inherit (pkgs)
    aspellDicts aspellWithDicts bash buildEnv coreutils fetchFromGitHub fetchgit
    fetchurl ispell makeBinaryWrapper perl python3 sqlite unzip writeTextFile;
  inherit (pkgs.stdenv) mkDerivation;
  inherit (pkgs.lib)
    concatMapStringsSep concatStringsSep getAttr licenses stringLength;

  # Reuse the repo's mysql2sqlite rather than re-vendoring it.
  mysql2sqlite = import ./mysql2sqlite.nix { inherit pkgs; };

  # Util
  lang-fullname = lang: replaceStrings [ " " ] [ "_" ] aspellDicts.${lang}.fullName;
  # Locale-pinned `sort`: collation must match the language, so wrap coreutils sort
  # with a single-locale glibcLocales and the matching LC_ALL. Kept here as nix code
  # (a derivation), not in lib — derivations don't belong in lib.
  sortUtil = lang: let
    localeLangStr = getAttr lang {
      da = "da_DK";
      de = "de_DE";
      el = "el_GR";
      en = "en_US";
      es = "es_ES";
      fi = "fi_FI";
      la = "en_US"; # for lack of an actual latin locale
      nb = "nb_NO";
      nn = "nn_NO";
      ru = "ru_RU";
      sv = "sv_SE";
    };
    localesPkg = pkgs.glibcLocales.override {
      allLocales = false;
      locales = [ "${localeLangStr}.UTF-8/UTF-8" ];
    };
    sortPkgForLang = mkDerivation {
      name = "sort-${lang}";
      buildInputs = [ coreutils makeBinaryWrapper localesPkg ];
      unpackPhase = "true"; # No src
      buildPhase = ''
        makeBinaryWrapper ${coreutils}/bin/sort sort-${lang} \
          --set LOCALE_ARCHIVE "${localesPkg}/lib/locale/locale-archive" \
          --set LC_ALL "${localeLangStr}.utf8"
      '';
      installPhase = ''
        mkdir -p $out/bin
        mv sort-${lang} $out/bin/
      '';
    };
  in {
    pkg = sortPkgForLang;
    cmd = "${sortPkgForLang}/bin/sort-${lang}";
  };
  sortPkg = lang: (sortUtil lang).pkg;
  sortCmd = lang: (sortUtil lang).cmd;

  # Extract word lists from wiktionary
  ## update
  wiktionary-dump-date = "20260601";
  # Each fetch tries upstream Wikimedia first, then the uxu.se mirror.
  page-sql-gz = fetchurl {
    urls = [
      "https://dumps.wikimedia.org/enwiktionary/20260601/enwiktionary-20260601-page.sql.gz"
      "https://uxu.se/mirror/enwiktionary-20260601-page.sql.gz"
    ];
    sha256 = "sha256-tnBZcjx7wfJxp02sNcz5KFy49Ejg3v7mMBAZNTDSmJ8=";
  };
  categorylinks-sql-gz = fetchurl {
    urls = [
      "https://dumps.wikimedia.org/enwiktionary/20260601/enwiktionary-20260601-categorylinks.sql.gz"
      "https://uxu.se/mirror/enwiktionary-20260601-categorylinks.sql.gz"
    ];
    sha256 = "sha256-1AEUREV5zbZtYgsr1yAlFxjO7+IMgnqSgZtPZcWmCAQ=";
  };
  # linktarget table added in MediaWiki 1.38+ - categorylinks.cl_target_id references linktarget.lt_id
  linktarget-sql-gz = fetchurl {
    urls = [
      "https://dumps.wikimedia.org/enwiktionary/20260601/enwiktionary-20260601-linktarget.sql.gz"
      "https://uxu.se/mirror/enwiktionary-20260601-linktarget.sql.gz"
    ];
    sha256 = "sha256-77vjrHxcBtf7ehdhALM5gnjhRwISqYr0oyMuF5ApooA=";
  };
  wiktionary-db = mkDerivation {
    name = "wiktionary-${wiktionary-dump-date}-sqlite.db";
    buildInputs = [ mysql2sqlite sqlite ];
    dontUnpack = true;
    buildPhase = ''
      gzip -d < "${page-sql-gz}" \
      | mysql2sqlite - \
      | grep -Ev '^(PRAGMA (synchronous|journal_mode)|(BEGIN|END) TRANSACTION|,  UNIQUE ..page_namespace)' \
      | sqlite3 $out
      gzip -d < "${categorylinks-sql-gz}" \
      | mysql2sqlite - \
      | grep -Ev '^(PRAGMA (synchronous|journal_mode)|(BEGIN|END) TRANSACTION)' \
      | sqlite3 $out
      gzip -d < "${linktarget-sql-gz}" \
      | mysql2sqlite - \
      | grep -Ev '^(PRAGMA (synchronous|journal_mode)|(BEGIN|END) TRANSACTION)' \
      | sed 's/INSERT INTO/INSERT OR IGNORE INTO/g' \
      | sqlite3 $out
    '';
    dontInstall = true;
    dontFixup = true;
  };
  wiktionary-words-for-language = lang: let
    language = lang-fullname lang;
    wiktionary-language =
      if lang == "nb"
      then "Norwegian_Bokmål"
      else language;
    # Note: MediaWiki 1.38+ replaced categorylinks.cl_to with cl_target_id -> linktarget.lt_id
    # We join through linktarget to get category titles
    infile = writeTextFile {
      name = "in.sql";
      text = ''
        select p.page_title
        from page p
          join categorylinks cl on p.page_id = cl.cl_from
          join linktarget lt on cl.cl_target_id = lt.lt_id
        where p.page_namespace=0
          and (lt.lt_title in ('${wiktionary-language}_lemmas'
                              ,'${wiktionary-language}_non-lemma_forms'
                              )
               or lt.lt_title like '${wiktionary-language}\__-syllable\_words' escape '\'
               or lt.lt_title like '${wiktionary-language}\___-syllable\_words' escape '\'
               or lt.lt_title like '${wiktionary-language}\_%\_nouns' escape '\'
               or lt.lt_title like '${wiktionary-language}\_%\_participles' escape '\'
               or lt.lt_title like '${wiktionary-language}\_%\_verbs' escape '\'
              )
          and p.page_id not in (select p2.page_id
                                from page p2
                                  join categorylinks cl2 on p2.page_id = cl2.cl_from
                                  join linktarget lt2 on cl2.cl_target_id = lt2.lt_id
                                where lt2.lt_title like '${wiktionary-language}\_Sign\_Language\_%' escape '\'
                                  or lt2.lt_title = '${wiktionary-language}_redlinks')
          and cl.cl_type = 'page';
      '';
    };
  in mkDerivation {
    inherit lang language;
    name = "words-${language}-wiktionary";
    buildInputs = [ mysql2sqlite sqlite (sortPkg lang) ];
    dontUnpack = true;
    buildPhase = ''
      mkdir -p $out/share/dict
      sqlite3 ${wiktionary-db} < ${infile} \
      | sed -r 's@^(${language}|Unsupported_titles)/@@;s@_@ @g;' \
      | ${sortCmd lang} \
      | uniq \
      > "$out/share/dict/${language}-wiktionary"
    '';
    dontInstall = true;
    dontFixup = true;
  };

  # Generate word lists using aspell
  aspell-words-for-language = lang: mkDerivation rec {
    inherit lang;
    language = lang-fullname lang;
    name = "words-${language}-aspell";
    buildInputs = [ (aspellWithDicts (x: [ x.${lang} ])) (sortPkg lang) ];
    dontUnpack = true;
    buildPhase = ''
      mkdir -p $out/share/dict
      export LANG=C.UTF-8
      aspell -d $lang dump master \
      | aspell -l $lang expand \
      | tr ' ' '\n' \
      | ${sortCmd lang} \
      > $out/share/dict/${language}-aspell
    '';
    dontInstall = true;
    dontFixup = true;
  };

  # Other, language specific word lists
  extra-wordlists = {
    sv = [ swedish-sslug ];
    en = [ english-scowl-v1 english-scowl-v2 english-misc ];
  };
  extra-wordlists-for-language = lang:
    if hasAttr lang extra-wordlists
    then getAttr lang extra-wordlists
    else [];
  swedish-sslug = mkDerivation rec {
    name = "words-Swedish-sslug";
    lang = "sv";
    language = "Swedish";
    src = fetchurl {
      url = "http://deb.debian.org/debian/pool/main/s/swedish/swedish_1.4.5.orig.tar.gz";
      hash = "sha256-oywn9rkx9TBheQkvWuBJjozGtBVBsZvNzqPiuN26QKc=";
    };
    buildInputs = [ ispell perl ];
    buildPhase = ''
      sed -ri 's@/bin/bash@${bash}/bin/bash@;' Makefile
      make svenska.ordlista
      iconv -f latin1 -t utf8 < svenska.ordlista > Swedish-sslug
    '';
    installPhase = ''
      mkdir -p $out/share/dict
      mv Swedish-sslug $out/share/dict
    '';
    meta = {
      license = licenses.gpl2Only;
      description = "Swedish dictionary";
      homepage = "https://web.archive.org/web/20120412182854/http://www.sslug.dk/locale/ispell/iswedish/svenska.html";
      downloadPage = "https://packages.debian.org/bookworm/text/wswedish";
      longDescription = ''
        Copyright (c) 1998 by Skåne/Sjælland Linux User Group <ispell@sslug.imm.dtu.dk>

        This swedish dictionary seems to have vanished off the internet except for a copy used to produce the debian package.

        See also:
        - https://www.cs.hmc.edu/~geoff/ispell-dictionaries.html#Swedish-dicts
      '';
    };
  };
  english-scowl-v1 = mkDerivation rec {
    name = "words-English-scowl-v1";
    lang = "en";
    language = "English";
    src = fetchFromGitHub {
      owner = "en-wl";
      repo = "wordlist";
      rev = "b22230cc5250887737fdefe9ca4c9d9d01230eaa";
      sha256 = "ppofwd7udm0SHXT2jsjBMIARf3gVxEbJlZ+fcVU9sOE=";
    };
    buildInputs = [ perl unzip (sortPkg lang) ];
    buildPhase = ''
      patchShebangs .
      make
    '';
    installPhase = ''
      mkdir -p $out/share/dict
      cat scowl/final/* \
      | iconv -f iso8859-1 -t utf-8 \
      | ${sortCmd lang} \
      | uniq \
      > $out/share/dict/English-scowl-v1
    '';
    meta = {
      license = licenses.mit;
      description = "SCOWL English dictionary";
      homepage = "http://wordlist.aspell.net/";
      downloadPage = "http://app.aspell.net/create";
      longDescription = ''
        The collective work is Copyright 2000-2018 by Kevin Atkinson as well
        as any of the copyrights mentioned below:

          Copyright 2000-2018 by Kevin Atkinson

          Permission to use, copy, modify, distribute and sell these word
          lists, the associated scripts, the output created from the scripts,
          and its documentation for any purpose is hereby granted without fee,
          provided that the above copyright notice appears in all copies and
          that both that copyright notice and this permission notice appear in
          supporting documentation. Kevin Atkinson makes no representations
          about the suitability of this array for any purpose. It is provided
          "as is" without express or implied warranty.
      '';
    };
  };
  english-scowl-v2 = mkDerivation rec {
    name = "words-English-scowl-v2";
    lang = "en";
    language = "English";
    src = fetchFromGitHub {
      owner = "en-wl";
      repo = "wordlist";
      ## update
      rev = "744c092883db13112f6680892850c1f1b6547b81";
      sha256 = "sha256-ts0uJNsz5y2aENOVvbFeYp1Sd81ATo2cDI7XZUJzjY8=";
    };
    buildInputs = [ python3 sqlite ];
    buildPhase = ''
      patchShebangs .
      make
      ./mk-list \
        --with-variants 3 \
        --accents both \
        --encoding utf-8 \
        en \
        en-us \
        en-gb-ise \
        en-gb-ize \
        en-gb-oed \
        en-ca \
        en-au \
        english \
        american \
        british \
        british-z \
        canadian \
        australian \
        variant-1 \
        variant-2 \
        variant-3 \
        british-variant-1 \
        british-variant-2 \
        canadian-variant-1 \
        canadian-variant-2 \
        australian-variant-1 \
        australian-variant-2 \
        special \
        100 \
        > English-scowl-v2
    '';
    installPhase = ''
      mkdir -p $out/share/dict
      mv English-scowl-v2 $out/share/dict/
    '';
    meta = {
      license = licenses.mit;
      description = "SCOWL English dictionary";
      homepage = "http://wordlist.aspell.net/";
      downloadPage = "http://app.aspell.net/create";
      longDescription = ''
        The collective work is Copyright 2000-2024 by Kevin Atkinson as well
        as any of the copyrights mentioned below:

          Copyright 2000-2024 by Kevin Atkinson

          Permission to use, copy, modify, distribute and sell these word
          lists, the associated scripts, the output created from the scripts,
          and its documentation for any purpose is hereby granted without fee,
          provided that the above copyright notice appears in all copies and
          that both that copyright notice and this permission notice appear in
          supporting documentation. Kevin Atkinson makes no representations
          about the suitability of this array for any purpose. It is provided
          "as is" without express or implied warranty.
      '';
    };
  };
  english-misc = mkDerivation rec {
    name = "words-English-misc";
    lang = "en";
    language = "English";
    src = fetchgit {
      url = "https://salsa.debian.org/debian/miscfiles.git";
      ## update
      rev = "ec40625b5e46081e4286b37b282b6e8fd03c1a61";
      sha256 = "tsYa7cWYAxNuRnsV9YqYaFXX/IxJET6rT4ZFDsRcBW4=";
    };
    buildInputs = [ (sortPkg lang) ];
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/share/dict
      mv connectives $out/share/dict/English-connectives
      mv propernames $out/share/dict/English-propernames
      cat web2 web2a | ${sortCmd lang} | uniq > $out/share/dict/English-websters
    '';
    meta = {
      license = licenses.gpl2;
      description = "Debian misc English dictionaries";
      homepage = "https://tracker.debian.org/pkg/miscfiles";
      downloadPage = "https://salsa.debian.org/debian/miscfiles";
      longDescription = ''
        connectives
            English `connectives'; prepositions, pronouns, and the like.

        propernames
            Some common proper names

        web2
          Webster's Second International English wordlist

        web2a
          Webster's Second Internations appendix english wordlist
      '';
    };
  };

  # Join word lists
  words-for-language = lang:
    let
      language = lang-fullname lang;
      paths = [
        (wiktionary-words-for-language lang)
        (aspell-words-for-language lang)
      ] ++ (extra-wordlists-for-language lang);
    in
      assert builtins.all (x: x.lang == lang && x.language == language) paths;
      buildEnv {
        name = "words-${language}";
        inherit paths;
        buildInputs = [ (sortPkg lang) ];
        postBuild = ''
          cat $out/share/dict/${language}-* \
          | ${sortCmd lang} \
          | uniq \
          > all-words;
          mv all-words $out/share/dict/${language}-all
        '';
      } // {
        inherit lang language;
      };
  words-for-languages = langs: let
    shortName = "words-for-${toString (length langs)}-languages";
    mediumName = "words-${concatStringsSep "-" langs}";
    longName = "words-${concatMapStringsSep "-" lang-fullname langs}";
    name =
      if stringLength longName < 100
      then longName
      else if length langs <= 10
      then mediumName
      else shortName;
  in
    buildEnv rec {
      inherit name;
      paths = map words-for-language langs;
    };
  words-en = words-for-language "en";

  # The generator API (mirrors the source's returned attrset).
  api = {
    inherit
      aspell-words-for-language
      english-scowl-v1
      english-scowl-v2
      lang-fullname
      swedish-sslug
      wiktionary-db
      wiktionary-words-for-language
      words-en
      words-for-language
      words-for-languages
    ;
  };

  # Flake `packages.<name>` must be a derivation, so expose a cheap representative
  # build (aspell English — no large fetches) and hang the full API off it. The
  # generator functions/derivations are reachable both directly (`.wordlists.<fn>`)
  # and via `.wordlists.passthru.<fn>`; building `.wordlists` builds only the cheap
  # aspell list (passthru is never realised by building the parent).
  default = aspell-words-for-language "en";
  meta = {
    description = "Multilingual wordlist generator (Wiktionary, aspell, SCOWL, Debian miscfiles, Swedish sslug)";
    longDescription = ''
      Generates dictionaries per language. The default package builds a small
      aspell-based English list; the full generator API is on passthru. Building
      the wiktionary path (`passthru.wiktionary-db`, or `words-for-language` for a
      language with wiktionary data) downloads multi-gigabyte Wikimedia SQL dumps.
    '';
    license = licenses.mit;
    platforms = pkgs.lib.platforms.all;
  };
in
default // { inherit meta; passthru = (default.passthru or { }) // api; } // api
