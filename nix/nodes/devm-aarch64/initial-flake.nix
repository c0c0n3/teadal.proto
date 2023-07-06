{
  inputs = {
    teadal.url = "github:c0c0n3/teadal.proto?dir=nix";
    nixos.follows = "teadal/nixpkgs";
  };

  outputs = { self, nixos, teadal }: {
    nixosConfigurations.devm = nixos.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        ./configuration.nix
        teadal.nixosModules
        ({ config, pkgs, ... }: {
            nixpkgs.overlays = [ teadal.overlay ];
            teadal.devm.enable = true;
            teadal.swapfile = {
              enable = true;
              size = 8192;  # MiB
            };
         })
      ];
    };
  };
}
