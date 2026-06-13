# Historic package collections, built from pinned nixpkgs releases.
# Returns plain (unmarked) attrsets; the discoverability marks (recurseIntoAttrs)
# are applied by the top-level ./default.nix so that checks/consumers importing
# this file directly are not polluted by the `recurseForDerivations` attribute.
{ pkgs
, # Forwarded to ./nixpkgs.nix (see there); null → its fetchFromGitHub default.
  fetchNixpkgsSrc ? null
}:

let
  inherit (pkgs) lib;
  system = pkgs.system;
  nixpkgs = import ./nixpkgs.nix { inherit pkgs fetchNixpkgsSrc; };
in
{
  inherit nixpkgs;
  ghostscript = import ./ghostscript.nix {
    inherit lib; history_nixpkgs = nixpkgs; };
  poppler-utils = import ./poppler-utils.nix {
    history_nixpkgs = nixpkgs; };
  python = import ./python.nix {
    inherit lib system; history_nixpkgs = nixpkgs; };
}
