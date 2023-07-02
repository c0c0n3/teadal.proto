#
# Aarch64-specific tweaks.
#
{ config, lib, pkgs,... }:

with lib;
with types;

{

  options = {
    teadal.k8s.aarch64.enable = mkOption {
      type = bool;
      default = false;
      description = ''
        Enable it to make our K8s config run on Aarch64.
      '';
    };
    teadal.k8s.aarch64.corednsImg = mkOption {
      description = ''
        Aarch64 CoreDNS Docker image. The default one in Nixpkgs 23.05
        isn't multi-achitecture, so we have to pick one for Aarch64 to
        make the container start.
      '';
      type = attrs;
      default = {
        imageName = "coredns/coredns";
        finalImageTag = "1.10.1";
        # the digest value is the docker image's sha, which you can get
        # by running:
        # docker pull coredns/coredns:1.10.1
        # docker inspect --format='{{index .RepoDigests 0}}' coredns/coredns:1.10.1
        # see:
        # - https://stackoverflow.com/questions/32046334/
        imageDigest = "sha256:a0ead06651cf580044aeb0a0feba63591858fb2e43ade8c9dea45a6a89ae7e5e";
        # the sha256 value is that of the docker image drv Nix builds.
        # - https://github.com/NixOS/nixpkgs/blob/nixos-23.05/nixos/modules/services/cluster/kubernetes/addons/dns.nix#L112
        # let the build bomb out, the error msg will tell you what the
        # sha256 should be.
        sha256 = "sha256-yXkgJW2SQcAFzjmBSAn2qo6O4m5AgMKwiT/LR+dqmzA=";
      };
    };
  };

  config = let
    enabled = pkgs.stdenv.isAarch64 && config.teadal.k8s.aarch64.enable;
    corednsImg = config.teadal.k8s.aarch64.corednsImg;
  in (mkIf enabled
  {
    services.kubernetes.addons.dns.coredns = corednsImg;

    services.etcd.extraConf = {
      # etcd won't start on aarch64 unless ETCD_UNSUPPORTED_ARCH is
      # set to "arm64". (Notice the Nixos module prefixes env vars
      # w/ `ETCD_`, hence the var name below.)
      "UNSUPPORTED_ARCH" = "arm64";
    };
  });

}
