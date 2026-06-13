# nur-packages

A personal [NUR](https://github.com/nix-community/NUR) repository: reusable Nix
functions and a curated collection of historic package versions.

## Functions and helpers

* `#lib`: Reusable Nix functions provided by this repository:
  * `attrToVersion`: a `vX_Y_Z` attribute name to its `X.Y.Z` version string.
  * `eachSystem` / `eachDefaultSystem`: vendored from [numtide/flake-utils](https://github.com/numtide/flake-utils) (MIT), so depending on this repository needs neither flake-utils nor a separate input.

## Historic software

Under `#history` are a few curated collections of software history
(`#history.python`, `#history.ghostscript`, `#history.poppler-utils`).
There is also `#history.nixpkgs`, a set of pinned nixpkgs releases you can reach
into for *any* historic package not curated directly — e.g.
`#history.nixpkgs.v21_05.pkgs.gzip`.

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

The packages live under `legacyPackages` (a nested namespace), so the easiest way
to explore is **shell completion** after `#history.`.

To **search or list** them, use `nix search` — not `nix flake show`. `nix flake
show` does not recurse `legacyPackages` (by design, exactly as for nixpkgs), so it
will only report it as `omitted`. `nix search` does recurse it:

```sh
# search the curated collections
> nix search github:svenssonaxel/nur-packages#legacyPackages.x86_64-linux ghostscript

# list every curated historic package (empty query matches all)
> nix search github:svenssonaxel/nur-packages#legacyPackages.x86_64-linux ''
```

The empty-query listing enumerates the curated `python` / `ghostscript` /
`poppler-utils` collections only — it deliberately does **not** descend into
`history.nixpkgs`, so you get the curated history, not a dump of every package in
every pinned nixpkgs. To reach those, address them directly as
`#history.nixpkgs.<release>.pkgs.<name>`.

These commands need no special flags: historic sources are fetched at evaluation
time, so browsing works on a fresh machine, on any system, without
`--option allow-import-from-derivation true`.
