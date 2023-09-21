{
  buildEnv,
  dockerTools,
  opa-envoy-plugin
}:
let
  cfg = import ./config.nix;
in dockerTools.buildImage {
  name = cfg.imgName;
  tag = cfg.pkgVer;

  copyToRoot = buildEnv {
    name = "opa-envoy-plugin-image-root";
    paths = [ opa-envoy-plugin ];
    pathsToLink = [ "/bin" ];
  };

  config = {
    Entrypoint = [ "/bin/${cfg.pname}" ];
    Cmd = [ "run" ];
    WorkingDir = "/data";
    Volumes = { "/data" = { }; };
  };
}
