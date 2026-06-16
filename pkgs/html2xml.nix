{ pkgs }:
let inherit (pkgs) lib libxml2 makeBinaryWrapper;
in pkgs.stdenv.mkDerivation {
  name = "html2xml";
  buildInputs = [ libxml2 makeBinaryWrapper ];
  unpackPhase = "true"; # No src
  buildPhase = ''
    makeBinaryWrapper ${libxml2}/bin/xmllint html2xml \
      --inherit-argv0 \
      --add-flags '--html --xmlout -'
  '';
  installPhase = ''
    mkdir -p $out/bin
    mv html2xml $out/bin
  '';
  meta = {
    description = "Wrapper around xmllint to convert HTML on stdin to XML on stdout";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
