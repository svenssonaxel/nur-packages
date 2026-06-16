# Smoke checks for published software (pkgs/*.nix). One check per package: build
# the package, then run a representative command. Wired into checks.<system> via
# checks.nix. Mirrors history/checks.nix's `mkCheck` (echo-then-run via `x`).
{ pkgs
}:

let
  published = import ./default.nix { inherit pkgs; };

  # `x` echoes then runs each command, so a failing step shows in the build log.
  mkCheck = label: script: pkgs.runCommand "check-pkgs-${label}" { } ''
    set -eu
    x() { echo "$@"; "$@"; }
    ${script}
    mkdir -p "$out"
    echo "${label} check passed" > "$out/result"
  '';
in
{
  # xmllint closes the open <p> tag, reflowing across lines; collapse whitespace
  # before matching so the `<p>hi</p>` round-trip is detected regardless of layout.
  html2xml = mkCheck "html2xml" ''
    got="$(echo '<p>hi' | ${published.html2xml}/bin/html2xml | tr -d ' \n\t')"
    echo "$got"
    case "$got" in *'<p>hi</p>'*) ;; *) echo "missing <p>hi</p>" >&2; exit 1 ;; esac
  '';

  markdown = mkCheck "markdown" ''
    got="$(echo '# hi' | ${published.markdown}/bin/markdown | tr -d ' \n\t')"
    echo "$got"
    case "$got" in *'<h1>hi</h1>'*) ;; *) echo "missing <h1>hi</h1>" >&2; exit 1 ;; esac
  '';

  exrex = mkCheck "exrex" ''
    x ${published.exrex}/bin/exrex --help
    x [ ! -e ${published.exrex}/bin/exrex.py ]
  '';

  domain-check = mkCheck "domain-check" ''
    got="$(${published.domain-check}/bin/domain-check --version)"
    echo "$got"
    case "$got" in *'1.0.1'*) ;; *) echo "missing version 1.0.1" >&2; exit 1 ;; esac
  '';

  # awk script: assert it is an executable file, then run it argument-less so it
  # prints its USAGE banner (to stderr) and exits 1 — captured, exit not asserted.
  mysql2sqlite = mkCheck "mysql2sqlite" ''
    bin=${published.mysql2sqlite}/bin/mysql2sqlite
    x [ -x "$bin" ]
    got="$("$bin" 2>&1 || true)"
    echo "$got"
    case "$got" in *USAGE*mysql2sqlite*) ;; *) echo "missing USAGE banner" >&2; exit 1 ;; esac
  '';

  # The upstream gzip-like wrapper's usage() always `exit 1` (even for --help), so
  # run it and assert the help banner rather than the exit code: the point is that
  # the wrapper resolves its PATH deps (sh, 7za, which, ...) and dispatches.
  p7zip-wrapper = mkCheck "p7zip-wrapper" ''
    got="$(${published.p7zip-wrapper}/bin/p7zip --help 2>&1 || true)"
    echo "$got"
    case "$got" in *Usage:*p7zip*) ;; *) echo "missing usage banner" >&2; exit 1 ;; esac
  '';

  # pgadmin4 is a web server — do NOT launch it. Just assert the wrapped binary
  # exists and that the wrapper defaults PGADMIN_SERVER_MODE to OFF (desktop mode).
  pgadmin = mkCheck "pgadmin" ''
    bin=${published.pgadmin}/bin/pgadmin4
    x [ -e "$bin" ]
    x grep -q 'PGADMIN_SERVER_MODE' "$bin"
    x grep -q "'OFF'" "$bin"
  '';

  # Latin-English dictionary: feed it a word then a blank line (which exits the
  # interactive prompt) and assert it translates `rosa` -> `rose`.
  whitakers-words = mkCheck "whitakers-words" ''
    got="$(printf 'rosa\n\n' | ${published.whitakers-words}/bin/whitakers-words)"
    echo "$got"
    case "$got" in *rose*) ;; *) echo "rosa did not translate to rose" >&2; exit 1 ;; esac
  '';

  # Downloads a ~3 GB model at RUNTIME, so we cannot transcribe in a sandboxed
  # build. Light check: wrapper exists/executable, `--help` runs and describes the
  # actual engine (Whisper) — and does NOT mention the old wrong help (Granite).
  transcribe-english = mkCheck "transcribe-english" ''
    bin=${published.transcribe-english}/bin/transcribe-english
    x [ -x "$bin" ]
    got="$("$bin" --help)"
    echo "$got"
    case "$got" in *Whisper*) ;; *) echo "help does not mention Whisper" >&2; exit 1 ;; esac
    case "$got" in *Granite*) echo "help still mentions Granite" >&2; exit 1 ;; *) ;; esac
  '';

  # Same shape: Swedish uses KB-Whisper-large via faster-whisper; assert the help
  # mentions Whisper and not the old wrong engine string (openai-whisper).
  transcribe-swedish = mkCheck "transcribe-swedish" ''
    bin=${published.transcribe-swedish}/bin/transcribe-swedish
    x [ -x "$bin" ]
    got="$("$bin" --help)"
    echo "$got"
    case "$got" in *Whisper*) ;; *) echo "help does not mention Whisper" >&2; exit 1 ;; esac
    case "$got" in *openai-whisper*) echo "help still mentions openai-whisper" >&2; exit 1 ;; *) ;; esac
  '';

  # wordlists pulls multi-GB Wikimedia dumps for its wiktionary path, so the smoke
  # check stays away from that: it builds the cheap aspell English list (the default
  # package, no large fetches) and asserts a non-empty, plausible-looking wordlist.
  wordlists = mkCheck "wordlists" ''
    list=${published.wordlists}/share/dict/English-aspell
    x [ -s "$list" ]
    n=$(wc -l < "$list"); echo "$n words"
    x [ "$n" -gt 1000 ]
    x grep -qx hello "$list"
  '';
}
