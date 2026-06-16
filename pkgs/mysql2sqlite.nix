{ pkgs }:
let
  inherit (pkgs.buildPackages) fetchFromGitHub;
  inherit (pkgs.stdenv) mkDerivation;
  inherit (import ../lib { inherit (pkgs) lib; }) shortrev;
  ## update
  rev = "d14d22ad7029cdf4d11825ee3c96922e8fbb0122";
  sha256 = "sha256-HHV+3oejJJ+3D6OLwivx1XoWSlZLw8NrMuN2n9SiZTk=";
  src = fetchFromGitHub {
    owner = "mysql2sqlite";
    repo = "mysql2sqlite";
    inherit rev sha256;
  };
  version = "0-unversioned";
in
mkDerivation {
  name = "mysql2sqlite-${shortrev rev}";
  inherit src version;
  buildPhase = ''
    mkdir -p $out/bin
    mv mysql2sqlite $out/bin
  '';
  meta = with pkgs.lib; {
    description = "Convert a MySQL dump to a SQLite-compatible dump";
    homepage = "https://github.com/mysql2sqlite/mysql2sqlite";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
