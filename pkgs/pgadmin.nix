# pgadmin4 wrapped to default to desktop (single-user) mode and keep argv0.
# Srcless wrapper; inherits name/version/meta from upstream pgadmin4.
# nixpkgs renamed `pgadmin` -> `pgadmin4` (alias throws on 26.05).
{ pkgs }:
let inherit (pkgs) makeShellWrapper; pgadmin = pkgs.pgadmin4;
in pkgs.stdenv.mkDerivation {
  inherit (pgadmin) name version;
  buildInputs = [ pgadmin makeShellWrapper ];
  unpackPhase = "true"; # No src
  buildPhase = ''
    makeShellWrapper ${pgadmin}/bin/pgadmin4 pgadmin4 \
      --inherit-argv0 \
      --set-default PGADMIN_SERVER_MODE OFF
  '';
  installPhase = ''
    mkdir -p $out/bin
    mv pgadmin4 $out/bin
  '';
  meta = pgadmin.meta;
}
