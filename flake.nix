{
  description = "Nix libraries, historic package versions, and published software";

  # nixpkgs is the only flake input; it is the single source of truth for the
  # base nixpkgs pin (recorded in flake.lock, which default.nix also reads).
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

  outputs = { self, nixpkgs }:
    let
      # eachSystem/eachDefaultSystem come from this repo's own lib (no flake-utils
      # input).
      ourLib = import ./lib { inherit (nixpkgs) lib; };

      # Fetch historic nixpkgs sources at eval time (M2; see history/nixpkgs.nix)
      # instead of via fetchFromGitHub. Both yield the same store path, but this
      # returns a plain path rather than a derivation, so importing it is NOT
      # import-from-derivation: `nix flake show` / `nix search` (which disable IFD)
      # work without any flag, on every system, including for untrusted clients.
      # Pinned by sha256, so it is pure-eval-safe. NUR cannot use this (its
      # restricted eval forbids eval-time fetches), so default.nix keeps the
      # fetchFromGitHub default.
      fetchNixpkgsSrc = version: sha256: builtins.fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/${version}.tar.gz";
        inherit sha256;
      };
    in
    {
      # Reachable as lib.eachDefaultSystem etc.; not exposed top-level, as that is
      # not a recognized flake output and `nix flake check` warns about it.
      lib = ourLib;
    }
    // ourLib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        # Exposed as legacyPackages, not packages, because the set is a nested
        # namespace (`.#history.python.v3_6`, `.#history.nixpkgs.v21_05`, with room
        # for non-historic siblings); packages.<system> may only hold flat
        # derivations. `history` and its collections carry the recurseForDerivations
        # marks (from default.nix), which `nix search` / `nix-env -qa` (and NUR)
        # follow to enumerate — so legacyPackages itself is left unmarked, keeping
        # `.#recurseForDerivations` out of the output. `nix flake show` does NOT
        # recurse legacyPackages by design — exactly as for nixpkgs — so browse with
        # `nix search .#legacyPackages.<system> <query>`.
        legacyPackages = {
          inherit (import ./default.nix { inherit pkgs fetchNixpkgsSrc; }) history;
        };
        checks = import ./checks.nix { inherit pkgs fetchNixpkgsSrc; };
      });
}
