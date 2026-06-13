# Flake-less entrypoint and NUR source of truth.
#
# NUR calls this as `import ./. { inherit pkgs; }` (see NUR's lib/evalRepo.nix,
# which passes the intersection of this file's formal args with { pkgs, lib }). So under
# NUR `pkgs` is always supplied and the default below is never evaluated — which
# is why that default may use builtins.fetchGit (not restrict-eval-safe): it runs
# only in plain flake / CLI use, never during NUR's restricted indexing. The pin
# is read from ./flake.lock — the single source of truth, shared with flake.nix's
# nixpkgs input — so run `nix flake lock` once to generate it. Historic versions
# are fetched with `pkgs.fetchFromGitHub` (a fixed-output derivation fetched at
# build time via IFD), which is restrict-eval-safe.
{ pkgs ? let lock = (builtins.fromJSON (builtins.readFile ./flake.lock)).nodes.nixpkgs.locked;
         in import (builtins.fetchGit {
              url = "https://github.com/${lock.owner}/${lock.repo}.git";
              inherit (lock) rev;
            }) { }
, # Optional override for how historic nixpkgs sources are fetched (see
  # history/nixpkgs.nix). NUR calls this file as `import ./. { pkgs }` (the
  # intersection of these formals with { pkgs, lib }), so it never supplies this
  # and the fetchFromGitHub default applies. flake.nix passes its eval-time
  # fetcher through here.
  fetchNixpkgsSrc ? null
}:

let
  recurse = pkgs.lib.recurseIntoAttrs;
  ourLib = import ./lib { inherit (pkgs) lib; };
  rawHistory = import ./history/default.nix { inherit pkgs fetchNixpkgsSrc; };
in
{
  # Reusable functions provided by this repository (NOT nixpkgs.lib); includes
  # eachDefaultSystem (under lib), so a consumer depending only on this repo
  # needs no flake-utils of their own.
  lib = ourLib;

  # Historic versions. Marked discoverable for NUR (recurseForDerivations) at the
  # collection level only; `nixpkgs` (the raw release set) stays unmarked so NUR
  # does not try to enumerate all of nixpkgs.
  history = recurse (rawHistory // {
    ghostscript = recurse rawHistory.ghostscript;
    poppler-utils = recurse rawHistory.poppler-utils;
    python = recurse rawHistory.python;
  });
}
