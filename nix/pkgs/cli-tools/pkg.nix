#
# Tools we use to install, develop and operate the cluster.
#
{
  symlinkJoin, buildEnv,

  pciutils, hwinfo, usbutils, smartmontools, du-dust, hdparm, sdparm,
  parted, tcpdump, ldns, nmap, ethtool, tree, bc, lsof, lesspipe,
  ripgrep, ripgrep-all, mkpasswd, unzip, zip, aria,

  git, kubectl, istioctl, argocd, kustomize, kubernetes-helm,
  qemu, nixos-rebuild,

  kubectl-directpv, kubectl-minio
}:

rec {

  # CLI tools to operate (Linux) cluster nodes.
  node-cli = [
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

  # Tools for K8s DevOps to be installed on every cluster node.
  node-cloud = [      # version (pkgs = nixos-23.05)
    kubectl-directpv  # 4.0.6
    kubectl-minio     # 5.0.6
    istioctl          # 1.17.2
    argocd            # 2.7.2
  ];

  # Tools to install on every cluster node.
  node = node-cli ++ node-cloud;

  # Tools for K8s stack dev & ops to be installed in dev shells.
  dev = [             # version (pkgs = nixos-23.05)
    git               # 2.40.1
    kubectl           # 1.27.1
    kustomize         # 5.0.3
    kubernetes-helm   # 3.11.3
    qemu              # 8.0.0
    nixos-rebuild
  ] ++ node-cloud;

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
  mkDev = name: mk name dev;

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
  mkDevShell = name: mkShell name dev;

  # Build packages and shells
  # - shared: tools that work both on Linux and MacOS.
  # - linux: tools that only work on Linux.
  shared = {
    cli-tools-dev = mkDev "cli-tools-dev";
    cli-tools-dev-shell = mkDevShell "cli-tools-dev-shell";
  };
  linux = {
    cli-tools-node = mkNode "cli-tools-node";
    cli-tools-node-shell = mkNodeShell "cli-tools-node-shell";
  };

}
