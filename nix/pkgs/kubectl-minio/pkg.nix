{
  fetchFromGitHub,
  buildGoModule                                               # NOTE (3)
}:
let
  gitTag = "v5.0.6";                                          # NOTE (1)
  pkgVer = "5.0.6";
in buildGoModule rec {
  pname = "kubectl-minio";
  version = pkgVer;
  src = fetchFromGitHub {
    owner = "minio";
    repo = "operator";
    rev = gitTag;
    sha256 = "sha256-b5UXZYpT+MS49pOFCz6l4YAo3dR2JnULB5Y1LOcO1tE=";
  };
  vendorSha256 = "sha256-UxeBAx4PMsMMVjdP5envnZWACDjlRHWMsGJUiy2EE1M=";
  modRoot = "./kubectl-minio";

  CGO_ENABLED = 0;                                            # NOTE (2)
  ldflags = [ "-s -w -X main.Version=${gitTag}" ];
}
# NOTE
# ----
# 1. How to update this package. Usual procedure but remember to set
# the hashes to `sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=`
# intially to force downloading source and Go modules for the new
# version.
#
# 2. Build flags. To figure out what to do, look at their `Makefile` and
# `.goreleaser.yaml` in the repo root dir. Also in the Makefile there's
# code gen build targets but, luckly, we don't need to run them b/c at tag
# `v5.0.6` all the files these targets generate are in git already.
# (TODO Or so it seems, make sure!)
# The original scripts build with the `-trimpath` flag but we don't need
# to specify it explicitly b/c buildGoModule's `allowGoReference` is false
# by default.
#
# 3. gomod2nix. That's usually a better option than buildGoModule but
# I couldn't manage to make it build the `kubectl-minio` binary. The
# one issue I couldn't work out is that the `kubectl-minio` dir comes
# with its own `go.mod` with a reference to its parent dir to include
# the shared Minio Operator code `kubectl-minio` depends on. So building
# a sub-package didn't work---i.e. `subPackages = [ "kubectl-minio" ]`.
# Changing the source root instead of building as a sub-package didn't
# work either---i.e. `sourceRoot = "${src}/kubectl-minio"`.
