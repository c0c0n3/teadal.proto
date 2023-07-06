#
# Make life a bit easier for admins.
#
{ config, lib, pkgs,... }:

with lib;
with types;

{

  options = {
    teadal.k8s.enableAdminAccess = mkOption {
      type = bool;
      default = false;
      description = ''
        Enable this if, besides `root`, also members of the `wheel` group
        should have built-in admin access to the cluster through `kubectl`
        on master nodes.
      '';
    };
  };

  config = let
    isMaster = builtins.elem "master" config.services.kubernetes.roles;
    enabled = isMaster && config.teadal.k8s.enableAdminAccess;
    kubeConfig = "/etc/kubernetes/cluster-admin.kubeconfig";
    kubeAdminKey = "/var/lib/kubernetes/secrets/cluster-admin-key.pem";
  in (mkIf enabled
  {
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
