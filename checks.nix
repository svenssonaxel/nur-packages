{ pkgs
, # Forwarded to the historic releases so checks use the same source fetcher as
  # legacyPackages; flake.nix passes its eval-time fetcher so `nix flake show`
  # (which evaluates checks too) needs no IFD. See history/nixpkgs.nix.
  fetchNixpkgsSrc ? null
}:

let
  ourLib = import ./lib { inherit (pkgs) lib; };
in
# Per-version build+version checks live in history as a nested module->version
# tree; flatten it into the `checks.<system>` set (e.g. `hello-v15_09`). The
# evaluation half of NUR indexing is covered by `./check`'s `nix-env -qa` pass.
ourLib.flattenDerivations (import ./history/checks.nix { inherit pkgs fetchNixpkgsSrc; })
