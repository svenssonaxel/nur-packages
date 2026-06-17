# Published software: current (non-historic) packages this repo maintains.
# Auto-discovers every `pkgs/*.nix` and `pkgs/<name>/` (except this file and
# checks.nix) and imports it with `{ inherit pkgs; }`, so adding a package needs
# no edit here. Each is `{ pkgs }:` (extra args allowed) returning a derivation.
# Empty directory => empty set.
{ pkgs
}:

let
  inherit (pkgs) lib;
  entries = lib.filterAttrs
    (name: type:
      (type == "directory" || (type == "regular" && lib.hasSuffix ".nix" name))
      && name != "default.nix" && name != "checks.nix")
    (builtins.readDir ./.);
  nameOf = file: lib.removeSuffix ".nix" file;
in
lib.mapAttrs' (file: _:
  lib.nameValuePair (nameOf file) (import (./. + "/${file}") { inherit pkgs; }))
  entries
