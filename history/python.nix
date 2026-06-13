{ lib
, system
, history_nixpkgs
}:

let
  inherit (lib) recursiveUpdate;
in {
  # v2_6_7 = history_nixpkgs.v0_14.pkgs.python26;
  # v2_6_9, v3_2..v3_5 build on the commented-out v15_09..v20_09 releases.
  # v2_6_9 =
  #   let config = { inherit system; config.allowBroken = true; };
  #       pkgs = history_nixpkgs.v15_09.nixpkgs config;
  #   in recursiveUpdate pkgs.python26 { meta.mainProgram = "python"; };
  v2_7   =
    let config = { permittedInsecurePackages = [ "python-2.7.18.8" ]; };
        pkgs = history_nixpkgs.v25_05.nixpkgs { inherit system config; };
    in pkgs.python27;
  # v3_2   = history_nixpkgs.v16_03.pkgs.python32;
  # v3_3   = history_nixpkgs.v17_03.pkgs.python33;
  # v3_4   = history_nixpkgs.v18_09.pkgs.python34;
  # v3_5   = history_nixpkgs.v20_03.pkgs.python35;
  v3_6   = history_nixpkgs.v21_05.pkgs.python36;
  v3_7   = history_nixpkgs.v22_11.pkgs.python37;
  v3_8   = history_nixpkgs.v23_11.pkgs.python38;
  v3_9   = history_nixpkgs.v24_11.pkgs.python39;
  v3_10  = history_nixpkgs.v25_05.pkgs.python310;
  v3_11  = history_nixpkgs.v25_05.pkgs.python311;
  v3_12  = history_nixpkgs.v25_05.pkgs.python312;
  v3_13  = history_nixpkgs.v25_05.pkgs.python313;
  v3_14  = history_nixpkgs.v25_05.pkgs.python314;
}
