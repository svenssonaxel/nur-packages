{ pkgs
}:

let
  history = import ./default.nix { inherit pkgs; };
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

  # Releases whose packages evaluate on the current system. Pre-aarch64 releases
  # (v15_09–v20_09 on aarch64-*) instantiate `.pkgs` but throw when a package is
  # forced, so the hello check (which forces `.pkgs.hello`) is emitted only for
  # supported pairs. The nixpkgs check below reads only `.src` (system-independent),
  # so it runs for every release.
  supportedReleaseAttrs = filterAttrs (_: rel: rel.supportsSystem) releaseAttrs;

  helloChecks = mapAttrs
    (v: rel: mkCheck "hello-${v}" ''
      x [ -e ${rel.pkgs.hello}/bin/hello ]
    '')
    supportedReleaseAttrs;

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
# Nested module -> version -> check derivations; flattened into checks.<system>.
{
  hello = helloChecks;
  nixpkgs = nixpkgsChecks;
  ghostscript = ghostscriptChecks;
  poppler-utils = popplerChecks;
  python = pythonChecks;
}
