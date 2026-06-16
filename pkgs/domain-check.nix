{ pkgs }:
pkgs.rustPlatform.buildRustPackage rec {
  pname = "domain-check";
  ## update
  version = "1.0.1";
  src = pkgs.fetchCrate {
    inherit pname version;
    hash = "sha256-z4UNTVGLnSLW9gyg4d9xWpLgNhl45rLlK9ARA/YMz3Y=";
  };
  cargoHash = "sha256-KJR/WmSyv4v9ZLEFc/ksVGT3pMBeqAjKZBnvVoP30yk=";
  doCheck = false; # tests require network access
  meta = {
    description = "Fast CLI to check domain name availability";
    mainProgram = "domain-check";
  };
}
