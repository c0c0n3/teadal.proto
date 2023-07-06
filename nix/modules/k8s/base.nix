#
# Basic tweaks.
#
{ config, lib, pkgs,... }:

with lib;
with types;

{

  options = {
    teadal.k8s.base.enable = mkOption {
      type = bool;
      default = false;
      description = ''
        Enable it to install our K8s base config.
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
    enabled = config.services.kubernetes.roles != [] &&
              config.teadal.k8s.base.enable;
    k8s = config.teadal.k8s.package;
  in (mkIf enabled
  {
    # Install K8s tools---kubectl & friends.
    environment.systemPackages = [ k8s ];

    # Configure a single-node K8s cluster---a bit of an oxymoron!
    services.kubernetes = {
        # Install the same version as in our ext option.
        package = k8s;

        # Use coredns.
        addons.dns.enable = true;

        # Allow privileged containers to run.
        # This is convenient for e.g. debugging traffic throuhg Istio sidecars
        # easily without starting a K8s debug container but not exactly the
        # best setup security-wise, so we should probably zap this setting in
        # the future.
        # See:
        #   - https://github.com/istio/istio/issues/30982
        #   - https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/#ephemeral-container
        #   - https://www.redhat.com/sysadmin/privileged-flag-container-engines
        apiserver.allowPrivileged = true;

        # Keep going even if this box has swap memory.
        # - https://kubernetes.io/blog/2021/08/09/run-nodes-with-swap-alpha/
        kubelet.extraOpts = "--fail-swap-on=false";        # NOTE (1)
    };
  });
}
# NOTE
# ----
# 1. Kubelet CLI flags deprecation. Most CLI flags have been deprecated
# in version 1.27 and the preferred approach is to use a config file
# instead:
# - https://kubernetes.io/docs/tasks/administer-cluster/kubelet-config-file/
#
# The `--fail-swap-on` is among the deprecated ones along with a ton that
# the Nixpkgs expression uses as you can see by running
#
# $ journalctl -u kubelet.service | grep kubelet-config-file
#
# So we're in good company. Indeed I couldn't find any easy way to access
# the Kubelet config file. Probably the current Nixpkgs expression will
# get updated at some point to move those flags to the config file and
# most likely there'll be a hook we should be able to use to migrate our
# `--fail-swap-on` to the Kubelet config file.
