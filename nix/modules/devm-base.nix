#
# TODO. docs.
#
{ config, lib, pkgs, ... }:

with lib;
with types;

{

  options = {
    ext.devm.enable = mkOption {
      type = bool;
      default = false;
      description = ''
        Enable it to install this dev VM's config.
      '';
    };
  };

  config = let
    enabled = config.ext.devm.enable;
  in (mkIf enabled
  {
    # Start from our OS base config, then set up a one-node K8s cluster.
    ext.base = {
      enable = true;
      cli-tools = pkgs.cli-tools-all;    # NOTE (1)
    };
    ext.k8s.dev-node.enable = true;      # NOTE (1)

    # Allow remote access through SSH, even for root.
    services.openssh = {
      enable = true;
      permitRootLogin = "yes";
    };

    # Get rid of the firewall.
    networking.firewall.enable = false;
  });

}
# NOTE
# ----
# 1. kubeclt. The `kubernetes` package brings in `kubectl` but it'll be
# the same version of that installed by `cli-tools-all` b/c it comes from
# the same nixpkg pin---see `flake.nix`. Not a train smash?
