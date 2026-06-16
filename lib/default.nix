# Reusable Nix functions provided by this repository, exposed as its `lib` output.
# Exposes only our own helpers (not nixpkgs.lib); takes nixpkgs `lib` to implement
# them. Per-function documentation is the /** */ doc-comments below — the single
# source of truth (rendered by nixdoc into README.md; see readme.nix).
{ lib
}:

rec {
  /**
    Convert a `vX_Y_Z` attribute name to its `X.Y.Z` version string.

    # Example
    ```nix
    attrToVersion "v3_6_1" => "3.6.1"
    ```
  */
  attrToVersion = builtins.replaceStrings [ "v" "_" ] [ "" "." ];

  /**
    Shorten a git revision to its 7-character prefix, for use in version strings.

    # Example
    ```nix
    shortrev "0123456789abcdef" => "0123456"
    ```
  */
  shortrev = rev: builtins.substring 0 7 rev;

  /**
    Flatten a nested tree of derivations into a single level, joining each path
    component with "-" (e.g. `{ hello.v15_09 = d; }` => `{ "hello-v15_09" = d; }`).
    Builds the flat `checks.<system>` / `packages.<system>` sets that flakes
    require. Merges with `unionOfDisjoint`, so any name collision throws rather
    than silently shadowing a leaf.
  */
  flattenDerivations = s:
    if lib.isDerivation s then s
    else lib.foldlAttrs
      (acc: name: v:
        let sub = flattenDerivations v; in lib.attrsets.unionOfDisjoint acc
          (if lib.isDerivation sub then { ${name} = sub; }
           else lib.mapAttrs' (k: lib.nameValuePair "${name}-${k}") sub))
      { } s;

  /**
    Recursively mark every attrset with `recurseIntoAttrs`, so `nix search`,
    `nix-env -qa` and NUR enumerate the derivations beneath it. Stops at derivation
    leaves, and is lazy (only marks attrsets that are forced). To exclude a subtree
    — e.g. a whole nixpkgs release set, which must not be descended into — override
    it back afterwards: `recurseIntoDerivations x // { inherit (x) nixpkgs; }`.
  */
  recurseIntoDerivations = s:
    if !(lib.isAttrs s) || lib.isDerivation s then s
    else lib.recurseIntoAttrs (lib.mapAttrs (_: recurseIntoDerivations) s);

  /**
    True during pure evaluation (e.g. flake outputs), where `builtins.currentSystem`
    and friends are unavailable. Same definition as nixpkgs' `lib.inPureEvalMode`.
  */
  inPureEvalMode = !(builtins ? currentSystem);

  /**
    True during restricted evaluation — NUR's indexer runs `restrict-eval`, where
    eval-time fetches of non-allow-listed URIs are forbidden (so a historic source
    must instead be fetched via a derivation, i.e. import-from-derivation).

    restrict-eval is the only mode that scrubs `getEnv` while remaining impure, so it
    is exactly: not pure-eval, yet `PATH` (essentially always set where nix runs) is
    empty. Robust by construction — under restrict-eval *every* variable is empty, so
    NUR is never missed; a false positive merely forces a build-time fetch, which
    also works. (There is no honest way to detect `allow-import-from-derivation`
    itself: its disabled error is uncatchable by `tryEval` and no builtin exposes the
    setting — so this restrict-eval signal is what source fetching keys on instead.)
  */
  inRestrictedEvalMode = !inPureEvalMode && builtins.getEnv "PATH" == "";

  # eachSystem / eachDefaultSystem are vendored from numtide/flake-utils (MIT); see
  # ./each-system.nix, where they carry their doc-comments.
  inherit (import ./each-system.nix) eachSystem eachDefaultSystem;
}
