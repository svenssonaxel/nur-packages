# nur-packages

A personal [NUR](https://github.com/nix-community/NUR) repository: reusable Nix
functions and a curated collection of historic package versions.

Examples below use the `github:svenssonaxel/nur-packages` flake reference; inside a
clone, `.` works in its place.

## Functions and helpers

Exposed under `#lib`. List them with `nix eval .#lib --apply builtins.attrNames`;
each is documented below (generated from the source doc-comments; see readme.nix).

<!-- BEGIN functions (generated; see readme.nix) -->
## `lib.attrToVersion`

Convert a `vX_Y_Z` attribute name to its `X.Y.Z` version string.

### Example
```nix
attrToVersion "v3_6_1" => "3.6.1"
```

## `lib.shortrev`

Shorten a git revision to its 7-character prefix, for use in version strings.

### Example
```nix
shortrev "0123456789abcdef" => "0123456"
```

## `lib.flattenDerivations`

Flatten a nested tree of derivations into a single level, joining each path
component with "-" (e.g. `{ hello.v15_09 = d; }` => `{ "hello-v15_09" = d; }`).
Builds the flat `checks.<system>` / `packages.<system>` sets that flakes
require. Merges with `unionOfDisjoint`, so any name collision throws rather
than silently shadowing a leaf.

## `lib.recurseIntoDerivations`

Recursively mark every attrset with `recurseIntoAttrs`, so `nix search`,
`nix-env -qa` and NUR enumerate the derivations beneath it. Stops at derivation
leaves, and is lazy (only marks attrsets that are forced). To exclude a subtree
— e.g. a whole nixpkgs release set, which must not be descended into — override
it back afterwards: `recurseIntoDerivations x // { inherit (x) nixpkgs; }`.

## `lib.inPureEvalMode`

True during pure evaluation (e.g. flake outputs), where `builtins.currentSystem`
and friends are unavailable. Same definition as nixpkgs' `lib.inPureEvalMode`.

## `lib.inRestrictedEvalMode`

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

## `lib.eachSystem`

Turn a `system: { <output> = v; }` function into `{ <output>.<system> = v; }`
across `systems` — e.g. build per-system `packages`/`checks` outputs.

## `lib.eachDefaultSystem`

`eachSystem` applied over the four default systems (`defaultSystems`).

<!-- END functions -->

## Historic software

Under `#history` are curated collections of software history
(`#history.python`, `#history.ghostscript`, `#history.poppler-utils`), plus
`#history.nixpkgs` — pinned nixpkgs releases for reaching any historic package not
curated directly. Each release `#history.nixpkgs.<release>` exposes:

* `.version` — the release version string;
* `.src` — the nixpkgs source tree;
* `.nixpkgs` — the imported nixpkgs (call it with your own args);
* `.pkgs` — that nixpkgs instantiated for the current system (e.g. `.pkgs.gzip`).

`.version`, `.src` and `.nixpkgs` are available on every system; `.pkgs` packages
only evaluate on systems the release predates the support cutoff of — `aarch64-linux`
from 17.03, `aarch64-darwin` from 21.05, `x86_64-{linux,darwin}` throughout — so the
per-release checks skip the unsupported pairs.

Examples:

```sh
> nix run github:svenssonaxel/nur-packages#history.python.v3_6 -- --version
Python 3.6.13
> nix run github:svenssonaxel/nur-packages#history.ghostscript.v10_01_1 -- --version
10.01.1
> nix run github:svenssonaxel/nur-packages#history.nixpkgs.v21_05.pkgs.gzip -- --version | head -n1
gzip 1.10
> nix shell github:svenssonaxel/nur-packages#history.poppler-utils.v21_05_0 -c pdfinfo -v 2>&1 | head -n1
pdfinfo version 21.05.0
```

### Browsing and searching

`nix flake show` does not recurse `legacyPackages` (by design, as for nixpkgs), so
browse with `nix search`:

```sh
> nix search github:svenssonaxel/nur-packages ghostscript   # search
> nix search github:svenssonaxel/nur-packages ''            # list all curated
```

The listing covers the curated collections only — not `#history.nixpkgs`, which you
address directly as `#history.nixpkgs.<release>.pkgs.<name>`.

<!-- BEGIN packages (generated; see readme.nix) -->
Curated packages:

* `#history.ghostscript.v9_53_3`
* `#history.ghostscript.v9_56_1`
* `#history.ghostscript.v10_01_1`
* `#history.ghostscript.v10_02_1`
* `#history.ghostscript.v10_04_0`
* `#history.ghostscript.v10_05_1`
* `#history.poppler-utils.v21_05_0`
* `#history.poppler-utils.v21_06_1`
* `#history.poppler-utils.v22_04_0`
* `#history.poppler-utils.v22_11_0`
* `#history.poppler-utils.v23_02_0`
* `#history.poppler-utils.v23_11_0`
* `#history.poppler-utils.v24_02_0`
* `#history.poppler-utils.v25_05_0`
* `#history.python.v2_7`
* `#history.python.v3_6`
* `#history.python.v3_7`
* `#history.python.v3_8`
* `#history.python.v3_9`
* `#history.python.v3_10`
* `#history.python.v3_11`
* `#history.python.v3_12`
* `#history.python.v3_13`
* `#history.python.v3_14`

Pinned nixpkgs releases (reach any package via `#history.nixpkgs.<release>.pkgs.<name>`):

* `#history.nixpkgs.v15_09`
* `#history.nixpkgs.v16_03`
* `#history.nixpkgs.v16_09`
* `#history.nixpkgs.v17_03`
* `#history.nixpkgs.v17_09`
* `#history.nixpkgs.v18_03`
* `#history.nixpkgs.v18_09`
* `#history.nixpkgs.v19_03`
* `#history.nixpkgs.v19_09`
* `#history.nixpkgs.v20_03`
* `#history.nixpkgs.v20_09`
* `#history.nixpkgs.v21_05`
* `#history.nixpkgs.v21_11`
* `#history.nixpkgs.v22_05`
* `#history.nixpkgs.v22_11`
* `#history.nixpkgs.v23_05`
* `#history.nixpkgs.v23_11`
* `#history.nixpkgs.v24_05`
* `#history.nixpkgs.v24_11`
* `#history.nixpkgs.v25_05`
* `#history.nixpkgs.v25_11`
* `#history.nixpkgs.v26_05`
<!-- END packages -->

## Published software

Under `#<name>` (a flat `packages.<system>` set) are the current, non-historic
packages this repository maintains. Build one with `nix build .#<name>`, or browse
them with `nix search`. The list below is generated (see readme.nix).

<!-- BEGIN published (generated; see readme.nix) -->
* `#domain-check`
* `#exrex`
* `#html2xml`
* `#markdown`
* `#mysql2sqlite`
* `#p7zip-wrapper`
* `#pgadmin`
* `#whitakers-words`
<!-- END published -->
