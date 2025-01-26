{
  description = "PostgreSQL backup and migration tool";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages = rec {
          pgbkp = pkgs.callPackage ./package.nix { };
          default = pgbkp;
        };

        apps = rec {
          pgbkp = flake-utils.lib.mkApp { drv = self.packages.${system}.pgbkp; };
          default = pgbkp;
        };
      });
}
