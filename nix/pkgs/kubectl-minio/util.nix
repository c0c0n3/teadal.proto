#
# Helpers functions to download and package Minio binaries.
#
rec {

  # Lookup a config item for a given system.
  # Params:
  # - sys: a Nixpkgs system label among those we support. At the moment one
  #   of "x86_64-linux", "aarch64-linux", "x86_64-darwin" or "aarch64-darwin".
  # - config: a list of attr sets where each set has a `sys` attribute set
  #   to one of the above labels.
  # - itemName: the name of the attribute to lookup in the attribute set
  #   whose `sys` attribute equals the given one.
  # Return:
  # The value of the `itemName` attribute in the attr set whose `sys` attr
  # equals the given one.
  #
  lookupSysConfigItem = config: itemName: sys:
  with builtins;
  let
    matches = filter (x: x.sys == sys) config;
    match = elemAt matches 0;  # let it bomb out if no matches
  in
    match.${itemName};

  # Map Nixpkgs arch labels to Minio's GitHub release suffixes.
  binPkgSuffixMap = [
    { sys = "x86_64-linux"; suffix = "linux_amd64"; }
    { sys = "aarch64-linux"; suffix = "linux_arm64"; }
    { sys = "aarch64-darwin"; suffix = "darwin_arm64"; }
    { sys = "x86_64-darwin"; suffix = "darwin_amd64"; }
  ];

  # Lookup Minio's GitHub release suffix for the given Nixpkgs arch.
  lookupBinPkgSuffix = lookupSysConfigItem binPkgSuffixMap "suffix";

  # Build the download URL for one of the binaries Minio releases on GitHub.
  # E.g.
  # - buildDownloadURL "https://github.com/minio/operator"
  #                    "kubectl-minio" "5.0.6"
  #                    "aarch64-darwin"
  #
  buildDownloadURL = repo: name: version: sys:
  let
    arch = lookupBinPkgSuffix sys;
  in
    "${repo}/releases/download/v${version}/${name}_${version}_${arch}";

  # Download one of the binaries Minio releases on GitHub.
  fetchBinary = {
    repo,    # e.g. "https://github.com/minio/operator"
    pname,   # e.g. "kubectl-minio"
    version, # e.g. "5.0.6"
    system,  # e.g. "aarch64-darwin"
    sha256 ? "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
             # ^ force build error if no valid sha256 is given.
  }:
  builtins.fetchurl {
    inherit sha256;
    url = buildDownloadURL repo pname version system;
  };

  # Bash command to install a Minio binary downloaded with `fetchBinary`
  # and referenced in the `src` attribute.
  installBinary =
  ''
    mkdir -p $out/bin
    cp $src $out/bin/$pname
    chmod 755 $out/bin/$pname
  '';

}
