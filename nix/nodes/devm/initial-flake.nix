{
  inputs = {
    teadal.url = "github:c0c0n3/teadal.proto?dir=nix";
    nixos.follows = "teadal/nixos";
  };

  outputs = { self, nixos, teadal }: {
    nixosConfigurations.devm = nixos.lib.nixosSystem {
      system = "x86_64-linux";  # change to match your system, e.g. aarch64-linux
      modules = [
        ./configuration.nix
        teadal.nixosModules
        ({ config, pkgs, ... }: {
            nixpkgs.overlays = [ teadal.overlay ];
            teadal.devm.enable = true;
            teadal.swapfile = {
              enable = true;
              size = 4096;  # MiB; tweak as needed.
            };
         })
      ];
    };
  };
}
