# Upstream X.Org xclock built from a git checkout (not the 1.1.1 release tarball):
# the XClock.Clock.*Shape render-clock resources the bundled variants rely on were
# merged upstream but postdate the xclock-1.1.1 release.
{ pkgs }:
let
  inherit (pkgs.buildPackages) fetchFromGitLab;
  shortrev = (import ../../lib { inherit (pkgs) lib; }).shortrev;
  ## update
  # e4c3873: render-clock shape resources used by the bundled variants postdate xclock-1.1.1.
  rev = "e4c38731fa9082512dfcfa39b7a5f37572fa4d6e";
  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "xorg/app";
    repo = "xclock";
    inherit rev;
    hash = "sha256-xSaINfTc1L4fb8wqtOqanZiiosJamutfyYLJZ0a55ac=";
  };
in
pkgs.xorg.xclock.overrideAttrs (old: {
  name = "xclock-upstream-${shortrev rev}";
  inherit src;
  version = "1.1.1-unstable-${shortrev rev}";
  # nixpkgs builds 1.1.1 with meson and patches meson support onto the release
  # tarball; that change is already upstream at this rev (meson.build ships in the
  # checkout), so the inherited patch no longer applies — drop it and build the
  # checkout's own meson directly.
  patches = [ ];
  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
  # nixpkgs's xclock wrapper sets XFILESEARCHPATH with a %N template (no %C); add a
  # %N%C entry so `xclock -xrm '*customization: -<v>'` finds XClock-<v>
  # (-ampm/-grandfather/-color).
  postInstall = (old.postInstall or "") + ''
    install -Dm444 ${./XClock-ampm} $out/share/X11/app-defaults/XClock-ampm
    install -Dm444 ${./XClock-grandfather} $out/share/X11/app-defaults/XClock-grandfather
    wrapProgram $out/bin/xclock \
      --prefix XFILESEARCHPATH : "$out/share/X11/app-defaults/%N%C"
  '';
})
