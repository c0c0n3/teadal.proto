#
# API Server basic tweaks.
#
{ config, lib, pkgs,... }:

with lib;
with types;

{

  options = {
    teadal.k8s.ensureDefaultAdmissionPlugins = mkOption {
      type = bool;
      default = false;
      description = ''
        Enable all default admission plugins. (NixOS only enables a
        subset of them.)
      '';
    };
    teadal.k8s.defaultAdmissionPlugins = mkOption {
      type = listOf str;
      default = [
        "NamespaceLifecycle" "LimitRanger" "ServiceAccount"
        "TaintNodesByCondition" "PodSecurity" "Priority"
        "DefaultTolerationSeconds" "DefaultStorageClass"
        "StorageObjectInUseProtection" "PersistentVolumeClaimResize"
        "RuntimeClass" "CertificateApproval" "CertificateSigning"
        "ClusterTrustBundleAttest" "CertificateSubjectRestriction"
        "DefaultIngressClass" "MutatingAdmissionWebhook"
        "ValidatingAdmissionPolicy" "ValidatingAdmissionWebhook"
        "ResourceQuota"
      ];
      # ^ Got this list by running:
      # kube-apiserver -h | grep enable-admission-plugins
      description = ''
        All default admission plugins in K8s 1.27.
      '';
    };
  };

  config = let
    enabled = config.teadal.k8s.ensureDefaultAdmissionPlugins;
    plugins = config.teadal.k8s.defaultAdmissionPlugins;
  in (mkIf enabled
  {
    services.kubernetes.apiserver.enableAdmissionPlugins = plugins;
  });

}
