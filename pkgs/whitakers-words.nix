# Built against v24_05/GNAT-12.3.0: 26.05's GNAT 13.x fatals the obsolescent-`with`
# warning (RM J.1, -gnatwj) under the project's -gnatwae, and gnat 11/12 were removed
# from 26.05. v24_05 is the repo's newest GNAT-12.3.0 pin (the same compiler stow
# builds it with), so the original -gnatwae compiles clean with no warning-flag hack.
{ pkgs }:
let
  p = (import ../history/nixpkgs.nix { inherit pkgs; }).v24_05.pkgs;
  inherit (p)
    fetchFromGitHub
    gnat
    gprbuild
    makeBinaryWrapper
  ;
  inherit (p.stdenv)
    mkDerivation
  ;
  inherit (p.lib)
    licenses
  ;
in mkDerivation {
  name = "whitakers-words";
  src = fetchFromGitHub {
    owner = "mk270";
    repo = "whitakers-words";
    ## update
    rev = "9b11477e53f4adfb17d6f6aa563669dc71e0a680";
    hash = "sha256-f/8dQff2min0FivBKTk/kcwwoW5IfajAjsdkALT52xU=";
  };
  buildInputs = [ gnat gprbuild ];
  nativeBuildInputs = [ makeBinaryWrapper ];
  installPhase = ''
    mkdir -p $out/bin $out/lib/whitakers-words
    cp bin/words bin/meanings *.GEN *.SEC $out/lib/whitakers-words
    makeBinaryWrapper $out/lib/whitakers-words/words $out/bin/whitakers-words --chdir $out/lib/whitakers-words
    makeBinaryWrapper $out/lib/whitakers-words/meanings $out/bin/whitakers-meanings --chdir $out/lib/whitakers-words
  '';
  meta = {
    license = licenses.free;
    description = "A Latin-English dictionary program";
    longDescription = ''
      Copyright William A. Whitaker (1936-2010)

      See also:
      - https://en.wikipedia.org/wiki/William_Whitaker%27s_Words
      - https://mk270.github.io/whitakers-words/
      - https://github.com/ArchimedesDigital/open_words
      - https://github.com/dsanson/Words
      - https://web.archive.org/web/20101208164945/http://users.erols.com/whitaker/wordsdev.htm
      - https://latin-words.com/
      - https://web.archive.org/web/20120423045230/http://sites.google.com/site/erikandremendoza/
      - https://sourceforge.net/p/wwwords/wiki/wordsdoc.htm/
      - https://johnwhiteauthor.co.uk/Whitaker_Words.htm
        - https://johnwhiteauthor.co.uk/WhitakerWordsWebsite/words.htm
        - https://johnwhiteauthor.co.uk/Whitaker_Obituary.htm
    '';
    homepage = "https://web.archive.org/web/20101202024150/http://users.erols.com/whitaker/words.htm";
    mainProgram = "words";
  };
}
