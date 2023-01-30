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
      k8s = if nixpkgs.legacyPackages.${prev.system} ? kubernetes then {
        k8s = nixpkgs.legacyPackages.${prev.system}.kubernetes;
      } else {};
    in {
      teadal = ours // k8s;    # NOTE (1)
    };

    modules = {
      nixosModules.imports = [ ./modules ];
    };
  in
    { inherit overlay; } // pkgs // modules;
}
# NOTE
# ----
# 1. Infinite recursion. Why not merge our packages right in the top-level
# set? i.e. the overlay could be
#
#   overlay = final: prev:
#   let
#     ours = ...;
#     k8s = ...;
#   in ours // k8s;
#
# This way our packages would be available as e.g. `pkgs.cli-tools-all`
# instead of `pkgs.teadal.cli-tools-all`. Except that causes Nix to blow
# up with an infinite recursion error. Gotta love fixed points.
#