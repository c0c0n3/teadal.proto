#
# Function to generate the Flake output for a given system.
#
{ # System label---e.g. "x86_64-linux", "x86_64-darwin", etc.
  system,
  # The Nix package set for the input system.
  sysPkgs,
  ...
}:
let
  tools = import ./pkg.nix { pkgs = sysPkgs; };

  isLinux = (builtins.match ".*-linux$" system) != null;
  shared = {
    cli-tools-cloud = tools.mkCloud "cli-tools-cloud";
    cli-tools-cloud-shell = tools.mkCloudShell "cli-tools-cloud-shell";
  };
  linux = {
    cli-tools-node = tools.mkNode "cli-tools-node";
    cli-tools-all = tools.mkAll "cli-tools-all";
    cli-tools-node-shell = tools.mkNodeShell "cli-tools-node-shell";
    cli-tools-all-shell = tools.mkAllShell "cli-tools-all-shell";
  };
in rec {
  packages.${system} = shared // (if isLinux then linux else {});
  defaultPackage.${system} = packages.${system}.cli-tools-cloud-shell;
}
