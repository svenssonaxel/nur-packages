# Historic package collections, built from pinned nixpkgs releases.
{ pkgs
}:

let
  inherit (pkgs) lib;
  system = pkgs.system;
  nixpkgs = import ./nixpkgs.nix { inherit pkgs; };
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
