# Reusable Nix functions provided by this repository, exposed as its `lib`
# output. Deliberately exposes only our own helpers, NOT nixpkgs.lib, so the
# surface stays focused on what this repository offers. Takes the nixpkgs `lib`
# purely to implement those helpers (e.g. flattenChecks' collision-safe merge).
{ lib
}:

let
  # eachSystem / eachDefaultSystem are vendored from numtide/flake-utils; see the
  # MIT notice in ./each-system.nix.
  flakeUtils = import ./each-system.nix;
in
rec {
  # `vX_Y_Z` attribute name -> `X.Y.Z` version string.
  attrToVersion = builtins.replaceStrings [ "v" "_" ] [ "" "." ];

  # Flatten a nested tree of derivations (e.g. module -> version -> derivation)
  # into a single level, joining each path with "-" (e.g. { hello = { v15_09 = d;
  # }; } -> { "hello-v15_09" = d; }). Builds the flat `checks.<system>` and
  # `packages.<system>` sets that flakes require (those reject nested attrsets,
  # unlike `legacyPackages`). Recurses to the derivation leaves, merging with
  # `unionOfDisjoint` so any name collision throws and no leaf is silently
  # shadowed (including ones the join creates, e.g. { a.b-c = …; a-b.c = …; }).
  flattenDerivations = s:
    if lib.isDerivation s then s
    else lib.foldlAttrs
      (acc: name: v:
        let sub = flattenDerivations v; in lib.attrsets.unionOfDisjoint acc
          (if lib.isDerivation sub then { ${name} = sub; }
           else lib.mapAttrs' (k: lib.nameValuePair "${name}-${k}") sub))
      { } s;

  inherit (flakeUtils) eachSystem eachDefaultSystem;
}
