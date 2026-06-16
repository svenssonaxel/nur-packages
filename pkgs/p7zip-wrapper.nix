{ pkgs }:
pkgs.stdenv.mkDerivation {
  name = "p7zip-wrapper";
  buildInputs = with pkgs; [ makeShellWrapper p7zip which ];
  unpackPhase = "true"; # No src
  buildPhase = ''
    SRC="${pkgs.p7zip.src}/contrib/gzip-like_CLI_wrapper_for_7z"
    [ -d "$SRC" ]
    [ -f "$SRC/man1/p7zip.1" ]
    [ -f "$SRC/p7zip" ]
    which sh
    which dirname
    which which
    which mktemp
    which 7za
    which rm
    which cat
    which tty
    mkdir -p $out/bin $out/share/man
    ln -s "$SRC/man1" $out/share/man/man1
    makeShellWrapper $(which sh) $out/bin/p7zip \
      --argv0 p7zip \
      --add-flags "$SRC/p7zip" \
      --prefix PATH : "$(dirname "$(which which)")" \
      --prefix PATH : "$(dirname "$(which mktemp)")" \
      --prefix PATH : "$(dirname "$(which 7za)")" \
      --prefix PATH : "$(dirname "$(which rm)")" \
      --prefix PATH : "$(dirname "$(which cat)")" \
      --prefix PATH : "$(dirname "$(which tty)")"
  '';
  installPhase = "";
}
