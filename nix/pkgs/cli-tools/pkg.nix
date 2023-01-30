#
# Tools we use to install, develop and operate the cluster.
#
{ pkgs }:

with pkgs;
rec {

  # CLI tools to operate (Linux) cluster nodes.
  node = [
    # Hardware:
    pciutils hwinfo usbutils
    # Disk:
    smartmontools du-dust hdparm sdparm parted
    # Network:
    tcpdump ldns nmap ethtool
    # Commands:
    tree bc lsof lesspipe ripgrep ripgrep-all mkpasswd
    # Compression: (they all work with lesspipe)
    unzip zip
    # Internet:
    aria
  ];

  # Tools for K8s stack dev & ops.
  cloud = [           # version (pkgs = nixos-unstable branch on 19 Jan 2023)
    git               # 2.39.0
    kubectl           # 1.26.0
    istioctl          # 1.16.1
    argocd            # 2.5.6
    kustomize         # 4.5.4
    kubernetes-helm   # 3.11.0
    qemu              # 7.2.0
  ];

  # Bundle all the given programs in a single derivation.
  # The derivation's bin dir will contain symlinks to all those programs.
  # See symlinkJoin docs.
  mk = name: paths: symlinkJoin {
    inherit name paths;
    # meta.priority = 1;
    # ^ usually not needed, but see
    # - https://stackoverflow.com/questions/58087058
  };
  mkNode = name: mk name node;
  mkCloud = name: mk name cloud;
  mkAll = name: mk name (node ++ cloud);

  # Make a shell env with all the given programs.
  # Notice we also add the program paths to the derivation so you can
  # reference them later if needed. E.g. in NixOS
  #
  #    environment.systemPackages = pkgs.cli-utils-shell.paths;
  #
  mkShell = name: paths: buildEnv {
    inherit name paths;
  } // { inherit paths; };
  mkNodeShell = name: mkShell name node;
  mkCloudShell = name: mkShell name cloud;
  mkAllShell = name: mkShell name (node ++ cloud);

}
