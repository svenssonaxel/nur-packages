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
}
