{ pkgs
}:

let
  inherit (import ../lib { inherit (pkgs) lib; }) attrToVersion inRestrictedEvalMode;
  system = pkgs.system;

  # Fetch a pinned nixpkgs source tree (release tag + its unpacked-NAR sha256) as an
  # importable path. Under restrict-eval (NUR) eval-time fetches are forbidden, so use
  # fetchFromGitHub (a derivation → import-from-derivation, which NUR allows);
  # otherwise builtins.fetchTarball — an eval-time fetch needing no IFD, so
  # `nix flake show` / `nix search` work flag-free on every system. Both fetchers
  # yield the identical store path.
  fetchNixpkgs = rev: sha256:
    if inRestrictedEvalMode
    then pkgs.fetchFromGitHub { owner = "NixOS"; repo = "nixpkgs"; inherit rev sha256; }
    else builtins.fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
      inherit sha256;
    };

  nixpkgsHashes = {
    # v0_1   = "0r0gh5fd8ag8mslxia9mybkqsi01wbnr8gq9f84k1j869cxbw1r4";
    # v0_2   = "0bjkp4jhkv45yqwggzdpzd581xvd0lrb4f9hla8dy4ah8kbmnzsv";
    # v0_3   = "0m2ahik6sxqp8j299gdbk84wjf41kl1cxpbbmc1gk576xrb4ls18";
    # v0_4   = "13m9z04rk39awp3lvx3dia8dl3m4iygp9y4fhj1xfkqqrryjkqf7";
    # v0_5   = "10k066wc4a1c207sd4mkcn41hrhckfrid2iq8q31ihwh5wc9s6im";
    # v0_5_1 = "00x4hf2hjfk32r4jij8wb80jnqmz0im1r6sfhgi3f33yz0g94a0i";
    # v0_6   = "044d4g0fgd93vv6mwm4lw5ndmb1ppsp89jbl3xjavi90nb4bxmmf";
    # v0_7   = "0w9d2p69fxay2bbg1hnicypdhmd2vqqw3rm4cyyzkd13ml6j7mcq";
    # v0_8   = "0sjsbzzm1vhknw644l3xmw0iy8mlmby0jxkv4qnyl1pxjn19wjbk";
    # v0_9   = "1j7p3sy68fjy3xhy6p5p9dmczl5z2x1573xhp53969w5xiyz26bd";
    # v0_10  = "0pcszg6v4nxs37k00rznfp9a06nc7khf15jl8fhcv9wn10rh4q3f";
    # v0_11  = "0c0biq1npkhciahwdylbicc5jprnn9kw8mhhcv5v7bi5z845sxgl";
    # v0_12  = "171wadjjb1xyk73ajndrhysxnicr5qmbv7b57sm8a1c0bnv1kb8h";
    # v0_13  = "0y3lfx67nq4n0wvsf9csz6arzzsb0kbgfrsgxxnx8ch90il8mf4y";
    # v0_14  = "0ymc0g3adrnil4fbrirlhbpjlgpl77zrjbsfjs445ms3z3p7mb1d";
    # v15_09 = "0pn142js99ncn7f53bw7hcp99ldjzb2m7xhjrax00xp72zswzv2n";
    # v16_03 = "0m2b5ignccc5i5cyydhgcgbyl8bqip4dz32gw0c6761pd4kgw56v";
    # v16_09 = "1cx5cfsp4iiwq8921c15chn1mhjgzydvhdcmrvjmqzinxyz71bzh";
    # v17_03 = "1fw9ryrz1qzbaxnjqqf91yxk1pb9hgci0z0pzw53f675almmv9q2";
    # v17_09 = "0kpx4h9p1lhjbn1gsil111swa62hmjs9g93xmsavfiki910s73sh";
    # v18_03 = "0hk4y2vkgm1qadpsm4b0q1vxq889jhxzjx3ragybrlwwg54mzp4f";
    # v18_09 = "1ib96has10v5nr6bzf7v8kw7yzww8zanxgw2qi1ll1sbv6kj6zpd";
    # v19_03 = "0q2m2qhyga9yq29yz90ywgjbn9hdahs7i8wwlq7b55rdbyiwa5dy";
    # v19_09 = "0mhqhq21y5vrr1f30qd2bvydv4bbbslvyzclhw0kdxmkgg3z4c92";
    # v20_03 = "0182ys095dfx02vl2a20j1hz92dx3mfgz2a6fhn31bqlp1wa8hlq";
    # v20_09 = "1wg61h4gndm3vcprdcg7rc4s1v3jkm5xd7lw8r2f67w502y94gcy";
    v21_05 = "1ckzhh24mgz6jd1xhfgx0i9mijk6xjqxwsshnvq789xsavrmsc36";
    v21_11 = "162dywda2dvfj1248afxc45kcrg83appjd0nmdb541hl7rnncf02";
    v22_05 = "0d643wp3l77hv2pmg2fi7vyxn4rwy0iyr8djcw1h5x72315ck9ik";
    v22_11 = "11w3wn2yjhaa5pv20gbfbirvjq6i3m7pqrq2msf0g7cv44vijwgw";
    v23_05 = "10wn0l08j9lgqcw8177nh2ljrnxdrpri7bp0g7nvrsn9rkawvlbf";
    v23_11 = "1ndiv385w1qyb3b18vw13991fzb9wg4cl21wglk89grsfsnra41k";
    v24_05 = "1lr1h35prqkd1mkmzriwlpvxcb34kmhc9dnr48gkm8hh089hifmx";
    v24_11 = "1gx0hihb7kcddv5h0k7dysp2xhf1ny0aalxhjbpj2lmvj7h9g80a";
    v25_05 = "1915r28xc4znrh2vf4rrjnxldw2imysz819gzhk9qlrkqanmfsxd";
    v25_11 = "1zn1lsafn62sz6azx6j735fh4vwwghj8cc9x91g5sx2nrg23ap9k";
    v26_05 = "0am8xx09fx5yf2p0wb001v0jx1g5hrfb76h4r37xph378jgk7pcr";
  };
  main = self: {
    inherit system nixpkgsHashes;
    mkVersion = version: src:
      let nixpkgs = import src;
      in {
        inherit version src nixpkgs;
        pkgs = nixpkgs { inherit (self) system; };
      };
    getFromTar = version: sha256:
      self.mkVersion version (fetchNixpkgs version sha256);
    releases = builtins.mapAttrs
      (v: h: self.getFromTar (attrToVersion v) h)
      self.nixpkgsHashes;
    versions = builtins.attrNames self.nixpkgsHashes;
    versionLinks = builtins.map (v: {
      name = v;
      path = self.releases.${v}.src;
    }) self.versions;
    allSources = pkgs.linkFarm
      "nixpkgs-releases-up-to-${pkgs.lib.last self.versions}" self.versionLinks;
    return = self.releases // {
      inherit (self) allSources;
    };
  };
in (pkgs.lib.fix main).return // { extendable = main; }
