{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
  pname = "pg-migrate";
  version = "1.0.0";

  src = ./.;

  buildInputs = with pkgs; [
    postgresql
    bash
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp script.sh $out/bin/pg-migrate
    chmod +x $out/bin/pg-migrate
  '';

  meta = with pkgs.lib; {
    description = "PostgreSQL database migration tool";
    platforms = platforms.unix;
    mainProgram = "pg-migrate";
  };
}
