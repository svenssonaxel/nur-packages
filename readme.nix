# README generator and freshness check, in one file (used by checks.<system>.readme).
#
# `generated` rebuilds ./README.md, filling the `<!-- BEGIN … -->` / `<!-- END … -->`
# regions with the lib-function docs (via nixdoc) and the historic-package list, while
# keeping all surrounding prose. `check` fails if the committed README differs.
#
# Regenerate after changing a lib doc-comment or the package set:
#   install -m644 "$(nix-build --no-out-link readme.nix -A generated)" README.md
#
# Not a flake output, so it stays off the package namespace.
{ pkgs ? let lock = (builtins.fromJSON (builtins.readFile ./flake.lock)).nodes.nixpkgs.locked;
         in import (builtins.fetchGit {
              url = "https://github.com/${lock.owner}/${lock.repo}.git";
              inherit (lock) rev;
            }) { }
}:

let
  inherit (pkgs) lib;
  history = (import ./default.nix { inherit pkgs; }).history;
  isVer = lib.hasPrefix "v";

  # Curated collections (exclude the raw nixpkgs set and the recurseForDerivations
  # mark). Pure: only attribute names are read, no derivation is forced.
  versionsOf = set: lib.naturalSort (builtins.filter isVer (builtins.attrNames set));
  collections = lib.filterAttrs (n: v: n != "nixpkgs" && lib.isAttrs v) history;
  curatedMd = lib.concatStringsSep "\n" (lib.concatLists (lib.mapAttrsToList
    (coll: versions: map (v: "* `#history.${coll}.${v}`") (versionsOf versions))
    collections));
  nixpkgsMd = lib.concatStringsSep "\n" (map
    (v: "* `#history.nixpkgs.${v}`")
    (versionsOf history.nixpkgs));
  packagesMd = ''
    Curated packages:

    ${curatedMd}

    Pinned nixpkgs releases (reach any package via `#history.nixpkgs.<release>.pkgs.<name>`):

    ${nixpkgsMd}'';

  functionsMd = pkgs.runCommand "functions.md" { nativeBuildInputs = [ pkgs.nixdoc ]; } ''
    doc() { nixdoc --prefix lib --category functions --description "" --file "$1"; }
    { doc ${./lib/default.nix}; doc ${./lib/each-system.nix}; } \
      | grep -v '{#sec-' \
      | sed -e 's/lib\.functions\./lib./g' -e 's/ {#[^}]*}//' \
      | cat -s | sed '/./,$!d' > $out
  '';

  generated = pkgs.runCommand "README.md"
    { inherit packagesMd; functionsFile = functionsMd; template = ./README.md; } ''
      splice() { # begin-marker end-marker content-file infile
        awk -v b="$1" -v e="$2" -v f="$3" '
          index($0, b) { print; while ((getline l < f) > 0) print l; close(f); s = 1; next }
          index($0, e) { s = 0; print; next }
          !s { print }
        ' "$4"
      }
      printf '%s\n' "$packagesMd" > packages.md
      splice "BEGIN functions" "END functions" "$functionsFile" "$template" > step1.md
      splice "BEGIN packages"  "END packages"  packages.md      step1.md   > $out
    '';
in
{
  inherit generated;
  check = pkgs.runCommand "check-readme" { } ''
    if diff -u ${./README.md} ${generated}; then touch $out
    else echo 'README.md is out of date; regenerate it (see readme.nix)' >&2; exit 1; fi
  '';
}
