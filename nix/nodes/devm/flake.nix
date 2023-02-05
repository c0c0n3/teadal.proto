{
  inputs = {
    teadal.url = "github:c0c0n3/teadal.proto?dir=nix";
    # ...or use the url below to deploy straight from your clone.
    # teadal.url = "../../";
    nixos.follows = "teadal/nixos";
  };

  outputs = { self, nixos, teadal }: {
    nixosConfigurations.devm = nixos.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ config, pkgs, ... }: { nixpkgs.overlays = [ teadal.overlay ]; })
        teadal.nixosModules
        ./configuration.nix
      ];
    };
  };
}
