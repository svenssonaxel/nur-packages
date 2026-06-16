{ pkgs }:
let
  perl = pkgs.perl;
  md = pkgs.perlPackages.TextMarkdown;
in pkgs.stdenv.mkDerivation {
  name = "${md.name}-patched";
  buildInputs = [ perl md ];
  src = md;
  buildPhase = ''
    cp bin/Markdown.pl markdown
    # Validate that first line is a shebang
    head -n 1 markdown > old_shebang
    grep -E '^#!/nix/.*/env perl$' old_shebang
    # Fix the shebang
    sed -ri '1 s@^.*$@#!/usr/bin/perl@;' markdown
    patchShebangs markdown

    # Man page
    gzip -d < share/man/man1/Markdown.pl.1.gz > markdown.1
    sed -ri 's/Markdown\.pl/markdown/g' markdown.1
  '';
  installPhase = ''
    mkdir -p $out/bin $out/share/man/man1
    mv markdown $out/bin
    mv markdown.1 $out/share/man/man1
  '';
  meta = md.meta;
}
