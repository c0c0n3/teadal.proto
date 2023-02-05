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
      # package = pkgs.teadal.k8s;
      # ^ uncomment the line above to install a more recent K8s than the
      # one that comes w/ the NixOS package set. (NixOS 22.11 ships K8s
      # 1.25.4.)
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
