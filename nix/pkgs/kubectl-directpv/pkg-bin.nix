#
# Download and install `kubectl-directpv` in the Nix store.
# We don't build the binary from soruce because the one Minio release on
# GitHub is a static build.
#
{ stdenv, system }:
let
  util = import ../kubectl-minio/util.nix;
  sha256Map = [              # NOTE (1)
    { sys = "x86_64-linux"; sha256 = "0imb2fj0f3v4pzn83kgzb47b7pg79cp2f5kc0gsdklzj36xsaarh"; }
    { sys = "aarch64-linux"; sha256 = "037k3xjn8vgj8gl9cqlik3zx0nhbdnxs5lrvbmkwnd3par3h2sdp"; }
    { sys = "aarch64-darwin"; sha256 = "1ahbkahjnjjcs8k6jvg3h486cwabqpnmxn0lgjziqd30r0f3p1s6"; }
    { sys = "x86_64-darwin"; sha256 = "0hshqni5zmj3if428511xv5p16wxqps8rdhhfbpf8a9l72wnnf21"; }
  ];
  sha256 = util.lookupSysConfigItem sha256Map "sha256" system;
in
stdenv.mkDerivation rec {
  pname = "kubectl-directpv";
  version = "4.0.6";

  src = util.fetchBinary {
    inherit system pname version sha256;
    repo = "https://github.com/minio/directpv";
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
#      repo = "https://github.com/minio/directpv";
#      pname = "kubectl-directpv";
#      version = "4.0.6";
#      system = "x86_64-darwin";
#    }
#
# It'll bomb out but will tell you what's the expected SHA256.
