{
  description = "Teadal cluster OS & tools.";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:NixOs/nixpkgs/645ff62e09d294a30de823cb568e9c6d68e92606";
                                               # ^ nixos-unstable branch on 01 Jul 2023.
    nixie = {
      url = "github:c0c0n3/nixie";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gomod2nix = {
      url = "github:nix-community/gomod2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixie, gomod2nix }:
  let
    inputPkgs = nixpkgs // {
      mkOverlays = system: [
        gomod2nix.overlays.default
        (final: prev: {
          argocd = nixpkgs-unstable.legacyPackages.${system}.argocd;
          istioctl = nixpkgs-unstable.legacyPackages.${system}.istioctl;
        })
      ];
    };
    build = nixie.lib.flakes.mkOutputSetForCoreSystems inputPkgs;
    pkgs = build (import ./pkgs/mkSysOutput.nix);

    modules = {
      nixosModules.imports = [ ./modules ];
    };
  in
    pkgs // modules;
}
