{
  description = "Personal collection of NixOS packages.";

  inputs = {
    nixos.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixos, flake-utils }@inputs:
    let
      importer = overlays: system:
        (import nixos {
          system = system;
          overlays = overlays;
        });
    in ({
      overlay = (final: prev: (import ./pkgs prev));
      overlays = {
        tools = (final: prev: (import ./pkgs/tools prev));
        science = (final: prev: (import ./pkgs/science prev));
        office = (final: prev: (import ./pkgs/office prev));
      };
      nixosModules = {
        wolfram-jupyter = (import ./modules/science/wolfram-jupyter);
      };
    } // (flake-utils.lib.eachSystem [ "x86_64-linux" ] (system: {
      packages = {
        fawkes = (importer [ self.overlay ] system).fawkes;
        onlyoffice-bin = (importer [ self.overlay ] system).onlyoffice-bin;
        wolfram-engine = (importer [ self.overlay ] system).wolfram-engine;
        mathematica-patched =
          (importer [ self.overlay ] system).mathematica-patched;
        wolfram-jupyter-kernel =
          (importer [ self.overlay ] system).wolfram-jupyter-kernel;
      };
    })));
}
