Dev env
-------
> Picks and shovels.

At the moment, we're using some basic tools to develop and manage
the Teadal cluster. Names & versions below.

* curl `8.1.1`
* git `2.40.1`
* jq `1.6`
* kubectl `1.27.1`
* kubectl-directpv `4.0.6`
* kubectl-minio `5.0.6`
* mc `RELEASE.2023-05-04T18-10-16Z`
* istioctl `1.18.0`
* argocd `2.7.6`
* kustomize `5.0.3`
* kubernetes-helm `3.11.3`
* opa `0.53.1`
* opa-envoy-plugin `0.53.1`
* qemu `8.0.0`

Please, like please, install the exact versions and if you do have
some of those tools already, make sure to always get a shell where
the right version of the tool is available—typically you'll need to
massage the `PATH` env var.

Alternatively, use our Nix shell. This is a sort of virtual shell
env on steroids which has in it all the tools you need with the
right versions. Plus, it doesn't pollute your box with libs that
could break your existing programs—everything gets installed in an
isolated Nix store dir and made available only in the Nix shell.

First off, you should install Nix and enable the Flakes extension

```bash
$ sh <(curl -L https://nixos.org/nix/install) --daemon
$ mkdir -p ~/.config/nix
$ echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
```

Now you can get into our Nix shell and have some fun with our tools.

```bash
$ nix shell github:c0c0n3/teadal.proto?dir=nix
$ argocd version --client --short
argocd: v2.5.6
```

Keep in mind if you cloned our repo, then you can also start a Nix
shell directly from there, e.g.

```bash
$ cd teadal.proto/nix
$ nix shell
```
