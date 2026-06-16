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
}
