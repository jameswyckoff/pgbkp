{ stdenv
, postgresql
, file
, makeWrapper
}:

stdenv.mkDerivation {
  pname = "pg-migrate";
  version = "1.0.0";

  src = ./script.sh;

  nativeBuildInputs = [ makeWrapper ];

  dontUnpack = true;

  installPhase = ''
    install -Dm755 $src $out/bin/pg-migrate
    wrapProgram $out/bin/pg-migrate \
      --prefix PATH : ${postgresql}/bin \
      --prefix PATH : ${file}/bin
  '';

  meta = with stdenv.lib; {
    description = "PostgreSQL database migration tool";
    platforms = platforms.unix;
    mainProgram = "pg-migrate";
  };
}
