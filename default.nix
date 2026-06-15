# Flake-less entry point and NUR source of truth. NUR imports this with `pkgs`
# supplied; the default below is only for bare CLI use (e.g. `nix-build ./.`) and
# reads the pin from ./flake.lock (shared with flake.nix's nixpkgs input).
{ pkgs ? let lock = (builtins.fromJSON (builtins.readFile ./flake.lock)).nodes.nixpkgs.locked;
         in import (builtins.fetchGit {
              url = "https://github.com/${lock.owner}/${lock.repo}.git";
              inherit (lock) rev;
            }) { }
}:

let
  ourLib = import ./lib { inherit (pkgs) lib; };
  rawHistory = import ./history/default.nix { inherit pkgs; };
in
{
  # Reusable functions provided by this repository (not nixpkgs.lib).
  lib = ourLib;

  # Historic versions, marked for discovery (nix search / nix-env / NUR). The raw
  # `nixpkgs` release set is left unmarked, so it is not enumerated.
  history = ourLib.recurseIntoDerivations rawHistory // { inherit (rawHistory) nixpkgs; };
}
