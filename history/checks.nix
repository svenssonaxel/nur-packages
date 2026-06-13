{ pkgs
, # Forwarded to ./default.nix so checks build from the same source fetcher as
  # legacyPackages (see history/nixpkgs.nix).
  fetchNixpkgsSrc ? null
}:

let
  history = import ./default.nix { inherit pkgs fetchNixpkgsSrc; };
  inherit (pkgs.lib) hasPrefix filterAttrs mapAttrs getName;
  inherit (import ../lib { inherit (pkgs) lib; }) attrToVersion;
  attrMatchesVer = attr: ver:
    (hasPrefix "${attrToVersion attr}." ver) || ((attrToVersion attr) == ver);
  progname = pkg: pkg.meta.mainProgram or (getName pkg);

  # One check derivation per version: `x` echoes then runs each command, so a
  # failing step shows up in the build log.
  mkCheck = label: script: pkgs.runCommand "check-${label}" { } ''
    set -eu
    x() { echo "$@"; "$@"; }
    ${script}
    mkdir -p "$out"
    echo "${label} check passed" > "$out/result"
  '';

  # Only the vX_Y nixpkgs releases (drop allSources and any non-release attr).
  releaseAttrs = filterAttrs (n: _: hasPrefix "v" n) history.nixpkgs;

  helloChecks = mapAttrs
    (v: rel: mkCheck "hello-${v}" ''
      x [ -e ${rel.pkgs.hello}/bin/hello ]
    '')
    releaseAttrs;

  nixpkgsChecks = mapAttrs
    (v: rel: mkCheck "nixpkgs-${v}" ''
      pkg="${rel.src}"
      if [ -e "$pkg/.version" ]
      then actual="$(cat "$pkg/.version")"
      elif [ -e "$pkg/VERSION" ]
      then actual="$(cat "$pkg/VERSION")"
      elif [ -e "$pkg/pkgs/VERSION" ]
      then actual="$(cat "$pkg/pkgs/VERSION")"
      else actual=""
      fi
      x [ "$actual" == "${attrToVersion v}" ]
    '')
    releaseAttrs;

  ghostscriptChecks = mapAttrs
    (attr: pkg:
      assert attrMatchesVer attr pkg.version;
      mkCheck "ghostscript-${attr}" ''
        program="${pkg}/bin/${progname pkg}"
        x [ -e "$program" ]
        actual="$($program --version)"
        x [ "$actual" == "${pkg.version}" ]
      '')
    history.ghostscript;

  popplerChecks = mapAttrs
    (attr: pkg:
      assert attrMatchesVer attr pkg.version;
      mkCheck "poppler-utils-${attr}" ''
        program="${pkg}/bin/pdfinfo"
        x [ -e "$program" ]
        actual="$($program -v 2>&1 | sed -r 's/.* //;2,$d')"
        x [ "$actual" == "${pkg.version}" ]
      '')
    history.poppler-utils;

  pythonChecks = mapAttrs
    (attr: pkg:
      assert attrMatchesVer attr pkg.version;
      mkCheck "python-${attr}" ''
        program="${pkg}/bin/${progname pkg}"
        x [ -e "$program" ]
        actual="$($program --version 2>&1)"
        x [ "$actual" == "Python ${pkg.version}" ]
      '')
    history.python;
in
# Nested module -> version -> check derivation; the top level flattens this into
# `checks.<system>` via lib.flattenAttrs (e.g. `hello-v15_09`).
{
  hello = helloChecks;
  nixpkgs = nixpkgsChecks;
  ghostscript = ghostscriptChecks;
  poppler-utils = popplerChecks;
  python = pythonChecks;
}
