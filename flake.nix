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
      overlays = {
        tools =
          (final: prev: { fawkes = (prev.callPackage ./pkgs/fawkes { }); });
      };
    } // (flake-utils.lib.eachSystem [ "x86_64-linux" ] (system: {
      packages = { fawkes = (importer [ self.overlays.tools ] system).fawkes; };
    })));
}
