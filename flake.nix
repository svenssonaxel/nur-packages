{
  description = "Nix libraries, historic package versions, and published software";

  # nixpkgs is the only flake input; it is the single source of truth for the
  # base nixpkgs pin (recorded in flake.lock, which default.nix also reads).
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = { self, nixpkgs }:
    let
      ourLib = import ./lib { inherit (nixpkgs) lib; };
    in
    {
      # Repo helpers, under the standard `lib` flake output.
      lib = ourLib;
    }
    // ourLib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        # legacyPackages, not packages: the set is a nested namespace
        # (`.#history.python.v3_6`), which packages.<system> may not hold.
        legacyPackages = {
          inherit (import ./default.nix { inherit pkgs; }) history;
        };
        checks = import ./checks.nix { inherit pkgs; };
      });
}
