{ history_nixpkgs
}:

# v = pkg: version: pkg // { inherit version; };
{
  # v0_18_4  = v history_nixpkgs.v0_14.pkgs.poppler "0.18.4";
  # v0_34_0  = v history_nixpkgs.v15_09.pkgs.poppler_utils "0.34.0";
  # v0_36_0  = v history_nixpkgs.v16_03.pkgs.poppler_utils "0.36.0";
  # v0_47_0  = v history_nixpkgs.v16_09.pkgs.poppler_utils "0.47.0";
  # v0_50_0  = v history_nixpkgs.v17_03.pkgs.poppler_utils "0.50.0";
  # v0_56_0  = v history_nixpkgs.v18_03.pkgs.poppler_utils "0.56.0";
  # v0_67_0  = v history_nixpkgs.v18_09.pkgs.poppler_utils "0.67.0";
  # v0_73_0  = v history_nixpkgs.v19_03.pkgs.poppler_utils "0.73.0";
  # v0_74_0  = v history_nixpkgs.v19_09.pkgs.poppler_utils "0.74.0";
  # v0_84_0  = history_nixpkgs.v20_03.pkgs.poppler_utils;
  # v20_08_0 = history_nixpkgs.v20_09.pkgs.poppler_utils;
  v21_05_0 = history_nixpkgs.v21_05.pkgs.poppler_utils;
  v21_06_1 = history_nixpkgs.v21_11.pkgs.poppler_utils;
  v22_04_0 = history_nixpkgs.v22_05.pkgs.poppler_utils;
  v22_11_0 = history_nixpkgs.v22_11.pkgs.poppler_utils;
  v23_02_0 = history_nixpkgs.v23_05.pkgs.poppler_utils;
  v23_11_0 = history_nixpkgs.v23_11.pkgs.poppler_utils;
  v24_02_0 = history_nixpkgs.v24_11.pkgs.poppler_utils;
  v25_05_0 = history_nixpkgs.v25_05.pkgs.poppler-utils;
}
