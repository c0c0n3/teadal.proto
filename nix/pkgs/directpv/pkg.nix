{ fetchFromGitHub, buildGoApplication }:

buildGoApplication {
  pname = "kubectl-directpv";
  version = "3.2.2";
  src = fetchFromGitHub {
    owner = "minio";
      repo = "directpv";
      rev = "v3.2.2";                                         # NOTE (1)
      sha256 = "mvEt2YcAkJ6u0r6BKNSmmhrMXQ/jDF0fi07WXVkTZVE=";
    };
  subPackages = [ "cmd/kubectl-directpv" ];
  modules = ./gomod2nix.toml;                                 # NOTE (1)
  doCheck = false;                                            # NOTE (2)
}
# NOTE
# ----
# 1. How to update this package.
#  - get a nix shell w/ gomod2nix
#  - clone the directpv repo
#  - checkout the tag corresponding to the version you want to build
#  - run gomod2nix in the repo root
#  - copy over here the generated `gomod2nix.toml` file
#  - update the sha256
#
# 2. Broken tests. Some tests are broken on MacOS which is why we're
# skipping the test phase for now.
