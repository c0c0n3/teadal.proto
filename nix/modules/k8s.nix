#
# TODO. docs.
#
{ config, lib, pkgs,... }:

with lib;
with types;

{

  options = {
    ext.k8s.dev-node.enable = mkOption {
      type = bool;
      default = false;
      description = ''
        Enable it to turn this machine into a single-node K8s cluster.
        This kind setup is only useful for development and testing, never
        to be used in a prod scenario :-)
      '';
    };
    ext.k8s.package = mkOption {
      type = package;
      default = pkgs.kubernetes;
      description = ''
        Kubernetes package to use.
      '';
    };
  };

  config = let
    enabled = config.ext.k8s.dev-node.enable;
    k8s = config.ext.k8s.package;
    # kubeconfig = TODO
  in (mkIf enabled
  {
    # Install K8s tools---kubectl & friends.
    environment.systemPackages = [ k8s ];

    # Configure a single-node K8s cluster---a bit of an oxymoron!
    services.kubernetes = {
        # Install the same version as in our ext option.
        package = k8s;

        # Squeeze all components in.
        # (apiserver, controllerManager, scheduler, addonManager, kube-proxy,
        # etcd, flannel, easyCerts and coredns.)
        masterAddress = "localhost";
        roles = [ "master" "node" ];
        addons.dns.enable = true;

        # Keep going even if this box has swap memory.
        # - https://kubernetes.io/blog/2021/08/09/run-nodes-with-swap-alpha/
        kubelet.extraOpts = "--fail-swap-on=false";

        # Broaden K8s node port range. So we'll be able to expose any K8s
        # node port we might use.
        apiserver.extraOpts = "--service-node-port-range=1-65535";
    };
    environment.variables = {
      KUBECONFIG = "/etc/kubernetes/cluster-admin.kubeconfig"; # TODO
    };
  });

}
# NOTE
# ----
# 1. Admin creds. From the NixOS manual:
#
# > By default, when easyCerts is enabled, a cluster-admin kubeconfig file
# > is generated and linked into /etc/kubernetes/cluster-admin.kubeconfig
# > as determined by services.kubernetes.pki.etcClusterAdminKubeconfig.
# > export KUBECONFIG=/etc/kubernetes/cluster-admin.kubeconfig will make
# > kubectl use this kubeconfig to access and authenticate the cluster.
# > The cluster-admin kubeconfig references an auto-generated keypair owned
# > by root. Thus, only root on the kubernetes master may obtain cluster-admin
# > rights by means of this file.
#
# See also:
# - https://github.com/NixOS/nixpkgs/blob/nixos-22.11/nixos/modules/services/cluster/kubernetes/pki.nix
