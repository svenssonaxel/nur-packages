{ pkgs }:

pkgs.symlinkJoin {
  name = "exrex-wrapper";
  paths = [ pkgs.python3Packages.exrex ];
  postBuild = ''
    rm -f $out/bin/exrex.py
  '';
}
