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

  isLinux = (builtins.match ".*-linux$" system) != null;
  # TODO use nixpkgs.lib.systems.inspect.predicates.isLinux?
  # It takes a set as an argument though...

  kubectl-directpv = sysPkgs.callPackage ./directpv/pkg.nix { };
  tools = sysPkgs.callPackage ./cli-tools/pkg.nix { inherit kubectl-directpv; };

in rec {
  packages.${system} =
    tools.shared // (if isLinux then tools.linux else {}) //
    { inherit kubectl-directpv; };
  defaultPackage.${system} = tools.shared.cli-tools-dev-shell;
}
