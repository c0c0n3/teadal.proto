#
# Function to generate the Flake output for a given system.
#
{ # System label---e.g. "x86_64-linux", "x86_64-darwin", etc.
  system,
  # The Nix package set for the input system, possibly with
  # overlays from other Flakes bolted on.
  sysPkgs,
  ...
}:

let

  isLinux = sysPkgs.stdenv.isLinux;

  # Install kubectl-directpv's GitHub binary release as is.    # NOTE (1)
  kubectl-directpv = sysPkgs.callPackage ./kubectl-directpv/pkg-bin.nix {
    inherit system;
  };
  # If you'd rather build from source, use this expression instead:
  # kubectl-directpv = sysPkgs.callPackage ./kubectl-directpv/pkg.nix { };

  # Install kubectl-minio's GitHub binary release as is.       # NOTE (1)
  kubectl-minio = sysPkgs.callPackage ./kubectl-minio/pkg-bin.nix {
    inherit system;
  };
  # If you'd rather build from source, use this expression instead:
  # kubectl-minio = sysPkgs.callPackage ./kubectl-minio/pkg.nix { };

  opa-envoy-plugin = sysPkgs.callPackage ./opa-envoy-plugin/pkg.nix { };
  opa-envoy-plugin-img = sysPkgs.callPackage ./opa-envoy-plugin/docker.nix {
    inherit opa-envoy-plugin;
  };

  tools = sysPkgs.callPackage ./cli-tools/pkg.nix {
    inherit kubectl-directpv kubectl-minio opa-envoy-plugin;
  };

in rec {
  packages.${system} =
    tools.shared // (if isLinux then tools.linux else {}) //
    { inherit kubectl-directpv kubectl-minio
              opa-envoy-plugin opa-envoy-plugin-img;
    };
  defaultPackage.${system} = tools.shared.cli-tools-dev-shell;
}
# NOTE
# ----
# 1. Binary packages. We don't build those ones from source b/c the
# binaries released on GitHub are statically linked. So we can just
# download them and install them which is much quicker. But you can
# still build from source with the `pkg.nix` expression if you like.
