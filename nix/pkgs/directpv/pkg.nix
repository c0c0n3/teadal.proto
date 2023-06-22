{
  fetchFromGitHub,
  buildGoApplication, gomod2nix
}:
let
  gitTag = "v4.0.5";                                          # NOTE (1)
  pkgVer = "4.0.5";
in buildGoApplication {
  pname = "kubectl-directpv";
  version = pkgVer;
  src = fetchFromGitHub {
    owner = "minio";
    repo = "directpv";
    rev = gitTag;
    sha256 = "sha256-0pPs2VCNWdmiEZyaqXIcYsk/o7bHsBWsZURFyOuuna8=";
  };
  subPackages = [ "cmd/kubectl-directpv" ];
  modules = ./gomod2nix.toml;
  nativeBuildInputs = [ gomod2nix ];                          # NOTE (2)
  CGO_ENABLED = 0;                                            # NOTE (3)
  tags = ["osusergo" "netgo" "static_build"];
  ldflags = "-X main.Version=${gitTag} -extldflags=-static";
}
# NOTE
# ----
# 1. How to update this package.
#  - get a nix shell w/ gomod2nix---see (2) below.
#  - clone the directpv repo
#  - checkout the tag corresponding to the version you want to build
#  - run gomod2nix in the repo root
#  - copy over here the generated `gomod2nix.toml` file
#  - update the sha256
#
# 2. gomod2nix. Added as an extra convenience to be able to easily generate
# `gomod2nix.toml`. In fact, with that in our native build inputs you can
# just run `nix develop .#kubectl-directpv` to get a shell with the tool.
#
# 3. Build flags. To figure out what to do, look at their `build.sh` and
# `.github/workflows/build.yaml` scripts. Also notice there's a code gen
# script (`codegen.sh`) that `build.sh` calls, but, luckly, we don't need
# to run it b/c at tag `v4.0.5` all the files this script generates are in
# git already. In fact, if you run yourself the script with the exact same
# versions of the Go tools in the script, you'll see that the generated
# files are the same as those in source control.
