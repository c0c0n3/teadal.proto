{
  description = "Teadal cluster OS & tools.";

  inputs = {
    nixos.url = "github:NixOs/nixpkgs/nixos-22.11";
    nixpkgs.url = "github:NixOs/nixpkgs/d7705c01ef0a39c8ef532d1033bace8845a07d35";
                                      # ^ nixos-unstable branch on 19 Jan 2023.
    nixie = {
      url = "github:c0c0n3/nixie";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixos, nixpkgs, nixie }:
  let
    build = nixie.lib.flakes.mkOutputSetByCartProdForCoreSystems nixpkgs;
    cli-tools = import ./pkgs/cli-tools/mkSysOutput.nix;
    # TODO directpv = import ./pkgs/directpv/mkSysOutput.nix;

    pkgs = build [ cli-tools ]; # TODO directpv ];

    overlay = final: prev:
    let
      ours = pkgs.packages.${prev.system} or {};
      k8s = {};
      # k8s = if nixpkgs.legacyPackages.${prev.system} ? kubernetes then {
      #   inherit (nixpkgs.legacyPackages.${prev.system}) kubernetes;
      # } else {};
    in
      ours // k8s;

    modules = {
      nixosModules.imports = [ ./modules ];
    };
  in
    { inherit overlay; } // pkgs // modules;
}
