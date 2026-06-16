{
  description = "Nix libraries, historic package versions, and published software";

  # nixpkgs is the source of truth for the base nixpkgs pin (recorded in
  # flake.lock, which default.nix also reads).
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  # flake-utils is re-exported as a top-level output for consumers who want the
  # real numtide/flake-utils (see the `flake-utils` output below). We do NOT
  # consume it ourselves: eachSystem/eachDefaultSystem are vendored in
  # lib/each-system.nix so the flakeless/NUR path (default.nix), which has no
  # flake inputs, needs no dependency. Its only transitive input is
  # nix-systems/default (no nixpkgs to dedupe), so no `follows` is needed.
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    let
      ourLib = import ./lib { inherit (nixpkgs) lib; };
    in
    {
      # Repo helpers, under the standard `lib` flake output.
      lib = ourLib;

      # Re-export the real flake-utils for consumers. Kept top-level (not folded
      # into `.lib`) so our `.lib` stays exactly our own helpers, and so the one
      # eachSystem they'd find here is not confused with our vendored copy.
      inherit flake-utils;
    }
    // ourLib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        # legacyPackages, not packages: the set is a nested namespace
        # (`.#history.python.v3_6`), which packages.<system> may not hold.
        legacyPackages = {
          inherit (import ./default.nix { inherit pkgs; }) history;
        };
        # Published software, a flat set of derivations, so `nix build .#<name>`
        # and `nix search` work. Auto-discovered from ./pkgs (empty for now).
        packages = import ./pkgs { inherit pkgs; };
        checks = import ./checks.nix { inherit pkgs; };
      });
}
