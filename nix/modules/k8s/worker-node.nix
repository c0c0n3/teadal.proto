#
# Kubernetes setup for a worker node in a (multi-node) cluster.
#
{ config, lib, pkgs,... }:

with lib;
with types;

{

  options = {
    teadal.k8s.worker-node.enable = mkOption {
      type = bool;
      default = false;
      description = ''
        Enable it to turn this machine into a K8s worker node.
      '';
    };
  };

  config = let
    enabled = config.teadal.k8s.worker-node.enable;
  in (mkIf enabled
  {
    # Configure a K8s worker node.
    services.kubernetes = {
        roles = [ "node" ];

        # TODO do we need any extra config?
    };
  });

}
