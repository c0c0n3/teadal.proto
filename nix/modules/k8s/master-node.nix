#
# Kubernetes setup for a master node in a (multi-node) cluster.
#
{ config, lib, pkgs,... }:

with lib;
with types;

{

  options = {
    teadal.k8s.master-node.enable = mkOption {
      type = bool;
      default = false;
      description = ''
        Enable it to turn this machine into a K8s master node.

        Notice that, besides `root`, also members of the `wheel` group
        have built-in admin access to the cluster through `kubectl`.
      '';
    };
  };

  config = let
    enabled = config.teadal.k8s.master-node.enable;
  in (mkIf enabled
  {
    # Configure a K8s master node.
    teadal.k8s.base.enable = true;
    services.kubernetes = {
        roles = [ "master" ];

        # Broaden K8s node port range. So we'll be able to expose any K8s
        # node port we might use. (But see NOTE (1)!)
        apiserver.extraOpts = "--service-node-port-range=1-10000";

        # TODO rest of the config!
    };

    # Enable all default admission plugins.
    teadal.k8s.ensureDefaultAdmissionPlugins = true;

    # Give `wheel` members admin access to the cluster when using `kubectl`.
    teadal.k8s.enableAdminAccess = true;

    # Addtional tweaks if running on Aarch64. (Does nothing if the box
    # isn't Aarch64.)
    teadal.k8s.aarch64.enable = true;

  });

}
# NOTE
# ----
# 1. Broadened port range. Well, it's a bit too broad. We take **a lot**
# of the possible ports which ups the chances of conflicts. The apiserver
# help warns you about it:
#
#  --service-node-port-range portRange
#  A port range to reserve for services with NodePort visibility.
#  This must not overlap with the ephemeral port range on nodes.
#
# This is okay for now, but we can do better. See e.g.
# - https://kubernetes.io/blog/2023/05/11/nodeport-dynamic-and-static-allocation/
