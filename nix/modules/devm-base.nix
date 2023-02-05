#
# TODO. docs.
#
{ config, lib, pkgs, ... }:

with lib;
with types;

{

  options = {
    teadal.devm.enable = mkOption {
      type = bool;
      default = false;
      description = ''
        Enable it to install this dev VM's config.
      '';
    };
  };

  config = let
    enabled = config.teadal.devm.enable;
  in (mkIf enabled
  {
    # Start from our OS base config, then set up a one-node K8s cluster.
    teadal.base = {
      enable = true;
      cli-tools = [ pkgs.teadal.cli-tools-node ];
    };
    teadal.k8s = {
      package = pkgs.teadal.k8s;
      dev-node.enable = true;
    };

    # Allow remote access through SSH, even for root.
    services.openssh = {
      enable = true;
      permitRootLogin = "yes";
    };

    # Get rid of the firewall.
    networking.firewall.enable = false;
  });

}
