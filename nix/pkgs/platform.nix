rec {

  isLinux = system: (builtins.match ".*-linux$" system) != null;
  # TODO use nixpkgs.lib.systems.inspect.predicates.isLinux?
  # It takes a set as an argument though...

  isAarch64 = system: (builtins.match "aarch64-.*" system) != null;
  # TODO use nixpkgs.lib.systems.inspect.predicates.isAarch64?
  # It takes a set as an argument though...
}
