#
# Kubernetes setup for a single-node cluster.
#
{ config, lib, pkgs,... }:

with lib;
with types;

{

  options = {
    teadal.k8s.dev-node.enable = mkOption {
      type = bool;
      default = false;
      description = ''
        Enable it to turn this machine into a single-node K8s cluster.
        This kind setup is only useful for development and testing, never
        to be used in a prod scenario :-)

        Notice that, besides `root`, also members of the `wheel` group
        have built-in admin access to the cluster through `kubectl`.
      '';
    };
  };

  config = let
    enabled = config.teadal.k8s.dev-node.enable;
  in (mkIf enabled
  {
    # Configure a single-node K8s cluster---a bit of an oxymoron!
    services.kubernetes = {
        # Squeeze all components in.
        # This node will run:
        # apiserver, controllerManager, scheduler, addonManager, kube-proxy,
        # etcd, flannel, easyCerts and coredns. (`base.nix` enables coredns.)
        roles = [ "master" "node" ];
        masterAddress = "localhost";

        # Broaden K8s node port range. So we'll be able to expose any K8s
        # node port we might use. (But see NOTE (1)!)
        apiserver.extraOpts = "--service-node-port-range=1-65535";
    };

    # Enable all default admission plugins.
    teadal.k8s.ensureDefaultAdmissionPlugins = true;

    # Give `wheel` members admin access to the cluster when using `kubectl`.
    teadal.k8s.enableAdminAccess = true;

  });

}
# NOTE
# ----
# 1. Broadened port range. Well, it's a bit too broad. We take **all**
# the possible ports which ups the chances of conflicts. The apiserver
# help warns you about it:
#
#  --service-node-port-range portRange
#  A port range to reserve for services with NodePort visibility.
#  This must not overlap with the ephemeral port range on nodes.
#
# This is okay for a dev box, but for prod we can do better. See e.g.
# - https://kubernetes.io/blog/2023/05/11/nodeport-dynamic-and-static-allocation/
