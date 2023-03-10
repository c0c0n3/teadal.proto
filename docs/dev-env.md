Dev env
-------
> Picks and shovels.

At the moment, we're using some basic tools to develop and manage
the Teadal cluster. Names & versions below.

* git `2.39.0`
* kubectl `1.26.0`
* istioctl `1.16.1`
* argocd `2.5.6`
* kustomize `4.5.4`
* kubernetes-helm `3.11.0`
* qemu `7.2.0`

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
