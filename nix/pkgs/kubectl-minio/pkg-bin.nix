#
# Download and install `kubectl-minio` in the Nix store.
# We don't build the binary from soruce because the one Minio release on
# GitHub is a static build.
#
{ stdenv, system }:
let
  util = import ./util.nix;
  sha256Map = [              # NOTE (1)
    { sys = "x86_64-linux"; sha256 = "0979mijbl271a6kbwagxb2w9w2kwmxr8wabnls9g3rjna3amfwb9"; }
    { sys = "aarch64-linux"; sha256 = "1n4rx9f8la58ks2834lfm7ibh3hfhp6vb7yh0xvshhrmirr1bp4m"; }
    { sys = "aarch64-darwin"; sha256 = "19bagsa570cfpidkm7l6lya2p64sfk6s2z8clxd4yl9b12xdvlsh"; }
    { sys = "x86_64-darwin"; sha256 = "1716af8jrhpyc35db6l8jc18r2x41lh6ikmj4rkpsl7h9q6z0261"; }
  ];
  sha256 = util.lookupSysConfigItem sha256Map "sha256" system;
in
stdenv.mkDerivation rec {
  pname = "kubectl-minio";
  version = "5.0.6";

  src = util.fetchBinary {
    inherit system pname version sha256;
    repo = "https://github.com/minio/operator";
  };
  sourceRoot = ".";

  phases = [ "installPhase" ];

  installPhase = util.installBinary;
}
# NOTE
# ----
# 1. How to update this package. You need to figure out what the new SHA256
# hashes are for the binary release you want to download. An easy way to do
# that is to load `util.nix` in the Nix REPL, then call `fetchBinary` with
# the new version but without the `sha256` attr as in
#
#    fetchBinary {
#      repo = "https://github.com/minio/operator";
#      pname = "kubectl-minio";
#      version = "5.0.6";
#      system = "x86_64-darwin";
#    }
#
# It'll bomb out but will tell you what's the expected SHA256.