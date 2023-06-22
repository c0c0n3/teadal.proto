{
  description = "Teadal cluster OS & tools.";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-23.05";
    nixie = {
      url = "github:c0c0n3/nixie";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gomod2nix = {
      url = "github:nix-community/gomod2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixie, gomod2nix }:
  let
    inputPkgs = nixpkgs // {
      mkOverlays = system: [ gomod2nix.overlays.default ];
    };
    build = nixie.lib.flakes.mkOutputSetForCoreSystems inputPkgs;
    pkgs = build (import ./pkgs/mkSysOutput.nix);

    overlay = final: prev:
    let
      ours = pkgs.packages.${prev.system} or {};
      k8s = if nixpkgs.legacyPackages.${prev.system} ? kubernetes then {
        k8s = nixpkgs.legacyPackages.${prev.system}.kubernetes;
      } else {};               # NOTE (2)
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
# 2. K8s version. Use this hook to get a newer K8s version if needed.
# Just define another Nixpkgs, e.g. nixpkgs-k8s, containing the newer
# version and then replace Nixpkgs as in the example below:
#
#   k8s = if nixpkgs-k8s.legacyPackages.${prev.system} ? kubernetes
