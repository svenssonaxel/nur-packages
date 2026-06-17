# `grandfather-xclock`: xclock with its grandfather-clock variant pre-loaded.
# Loads the variant via XENVIRONMENT (precedence above RESOURCE_MANAGER) so it
# applies in full regardless of the user's own xclock resources; the `customization`
# route is lowest precedence and would be overridden.
{ pkgs }:

let
  xclock = import ./xclock { inherit pkgs; };
in
pkgs.stdenv.mkDerivation {
  pname = "grandfather-xclock";
  inherit (xclock) version;

  dontUnpack = true;

  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    makeWrapper ${xclock}/bin/xclock $out/bin/grandfather-xclock \
      --set XENVIRONMENT ${xclock}/share/X11/app-defaults/XClock-grandfather
  '';

  meta = {
    description = "Upstream xclock styled as a grandfather clock";
    mainProgram = "grandfather-xclock";
    inherit (xclock.meta) license platforms;
  };
}
