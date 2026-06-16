{ pkgs
}:

let
  ourLib = import ./lib { inherit (pkgs) lib; };
in
# Flatten into checks.<system>; the `history` level leaves room for future
# top-level checks (e.g. `history-hello-v21_05`). `readme` asserts README.md's
# generated sections are current.
ourLib.flattenDerivations {
  history = import ./history/checks.nix { inherit pkgs; };
  pkgs = import ./pkgs/checks.nix { inherit pkgs; };
}
// { readme = (import ./readme.nix { inherit pkgs; }).check; }
