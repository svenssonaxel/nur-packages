{ lib
, history_nixpkgs
}:

# gs = pkg: lib.recursiveUpdate pkg { meta.mainProgram = "gs"; };
{
  # v9_15    = gs history_nixpkgs.v15_09.pkgs.ghostscript // { version = "9.15"; };
  # v9_18    = gs history_nixpkgs.v16_09.pkgs.ghostscript;
  # v9_20    = gs history_nixpkgs.v17_09.pkgs.ghostscript;
  # v9_22    = gs history_nixpkgs.v18_03.pkgs.ghostscript;
  # v9_24    = gs history_nixpkgs.v18_09.pkgs.ghostscript;
  # v9_26    = gs history_nixpkgs.v19_09.pkgs.ghostscript;
  # v9_50    = gs history_nixpkgs.v20_03.pkgs.ghostscript;
  # v9_52    = gs history_nixpkgs.v20_09.pkgs.ghostscript;
  v9_53_3  = history_nixpkgs.v21_11.pkgs.ghostscript;
  v9_56_1  = history_nixpkgs.v22_11.pkgs.ghostscript;
  v10_01_1 = history_nixpkgs.v23_05.pkgs.ghostscript;
  v10_02_1 = history_nixpkgs.v24_05.pkgs.ghostscript;
  v10_04_0 = history_nixpkgs.v24_11.pkgs.ghostscript;
  v10_05_1 = history_nixpkgs.v25_05.pkgs.ghostscript;
}
