#
# Kubernetes setups for single-node and multi-node clusters.
# (Multi-node still in the making...)
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
    teadal.k8s.package = mkOption {
      type = package;
      default = pkgs.kubernetes;
      description = ''
        Kubernetes package to use.
      '';
    };
  };

  config = let
    enabled = config.teadal.k8s.dev-node.enable;
    k8s = config.teadal.k8s.package;
    kubeConfig = "/etc/kubernetes/cluster-admin.kubeconfig";
    kubeAdminKey = "/var/lib/kubernetes/secrets/cluster-admin-key.pem";
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

        # Extra tweaks.
        # - Broaden K8s node port range. So we'll be able to expose
        #   any K8s node port we might use.
        # - Allow privileged containers to run.
        # - Enable all default admission plugins. (NixOS only enables
        #   a subset of them.)
        apiserver = {
          allowPrivileged = true;
          extraOpts = "--service-node-port-range=1-65535";
          enableAdmissionPlugins = [
            "NamespaceLifecycle" "LimitRanger" "ServiceAccount"
            "TaintNodesByCondition" "PodSecurity" "Priority"
            "DefaultTolerationSeconds" "DefaultStorageClass"
            "StorageObjectInUseProtection" "PersistentVolumeClaimResize"
            "RuntimeClass" "CertificateApproval" "CertificateSigning"
            "CertificateSubjectRestriction" "DefaultIngressClass"
            "MutatingAdmissionWebhook" "ValidatingAdmissionWebhook"
            "ResourceQuota"
          ];
          # ^ Got this list by running:
          # kube-apiserver -h | grep enable-admission-plugins
        };
    };

    # Give `wheel` members admin access to the cluster when using `kubectl`.
    # See NOTE (1) and (2).
    environment.variables = {
      KUBECONFIG = kubeConfig;
    };
    system.activationScripts.k8sAdminAccess =
      stringAfter [ "users" "usrbinenv" ] ''
        chgrp wheel ${kubeAdminKey}
        chmod 0640 ${kubeAdminKey}
      '';

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
#
# 2. Admin access to the K8s cluster. So `root` has admin access to the
# cluster, but we want our `admin` user to also have it. Now, this is the
# content of the generated `/etc/kubernetes/cluster-admin.kubeconfig`
#
# apiVersion: v1
# clusters:
# - cluster:
#     certificate-authority: "/var/lib/kubernetes/secrets/ca.pem"
#     server: https://localhost:6443
#   name: local
# contexts:
# - context:
#     cluster: local
#     user: cluster-admin
#   name: local
# current-context: local
# kind: Config
# users:
# - name: cluster-admin
#   user:
#     client-certificate: "/var/lib/kubernetes/secrets/cluster-admin.pem"
#     client-key: "/var/lib/kubernetes/secrets/cluster-admin-key.pem"
#
# Both `ca.pem` and `cluster-admin.pem` are world-readable, but (rightly
# so) no one except for `root` can read `cluster-admin-key.pem`. So we
# need `wheel` members to be able to read this file too.
