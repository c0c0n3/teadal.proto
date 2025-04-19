{
  fetchFromGitHub,
  buildGoModule                                               # NOTE (3)
}:
let
  cfg = import ./config.nix;                                  # NOTE (1)
in buildGoModule rec {
  pname = cfg.pname;
  version = cfg.pkgVer;
  src = fetchFromGitHub {
    owner = "open-policy-agent";
    repo = "opa-envoy-plugin";
    rev = cfg.gitTag;
    sha256 = "sha256-IJe/JKdsjJ0oJWa35UjxXHiVsm7M1mFwVx5oQ45uuSE=";
  };
  vendorHash = null;
  subPackages = [ "cmd/opa-envoy-plugin" ];

  env = {                                                     # NOTE (2)
    CGO_ENABLED = 0;
    WASM_ENABLED = 0;
  };
  ldflags = [
    "-X github.com/open-policy-agent/opa/version.Version=${cfg.gitTag}"
  ];

  postConfigure = ''
    go generate ./...
  '';
}
# NOTE
# ----
# 1. How to update this package. Usual procedure but remember to set
# the src hash to `sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=`
# initially to force downloading Go sources. Because there's a vendor
# folder, `vendorHash` needs to be `null`. In fact, `buildGoModule`
# warns you about it
#   vendor folder exists, please set
#   'vendorHash = null;' or 'vendorSha256 = null;
#
# 2. Build flags. To figure out what to do, look at their `Makefile`.
# `buildGoModule` already sets `GOFLAGS=-mod=vendor`, `GO111MODULE=on`
# and `GOPROXY=off`. `CGO_ENABLED` and `WASM_ENABLED` we set ourselves
# whereas the remaining setting we don't really need them.
#
# 3. gomod2nix. That's usually a better option than buildGoModule but
# I couldn't manage to make it build the `opa-envoy-plugin` binary.
# The one issue I couldn't work out is that the code uses both modules
# and vendoring it seems, so I get this error when building with
# `buildGoApplication`: `cannot query module due to -mod=vendor`.
