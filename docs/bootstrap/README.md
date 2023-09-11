Teadal cloud rollout
--------------------
> From zero to hero!

How do you build the Teadal cloud from scratch? We've got a sort
of streamlined procedure you can follow. It shouldn't be too hard,
but surely there's still plenty of room for improvement.

In a nutshell, you've got to

1. [Set up a baseline K8s cluster][k8s-baseline]. Install a K8s baseline
   we can later use to host our cloud stack—Istio & add-ons, Argo CD, etc.
   The outcome should be a fully-fledged, K8s `1.27.1` cluster. We do this
   with NixOS so we can fully manage nodes remotely through config files
   in a Git repo. Plus, we can reproduce the **exact same stack** on dev
   boxes as well, to keep "works on my machine" accidents from happening.
2. [Configure cluster admin access][admin-access]. Set up admin access
   to your freshly minted K8s cluster.
3. [Bootstrap the Teadal mesh][mesh]. Set up the Istio mesh and the
   Argo CD pipelines to deploy and manage the Teadal cloud services
   and supporting K8s resources.

Notice that (3) doesn't really depend on any of the NixOS stuff we
roll out in (1). If for some reason you don't want to use NixOS and
you can provide your own fully-fledged K8s `1.27.1` cluster, then skip
(1) and (2) and jump right into (3). In fact, you could, for example,
set up a MicroK8s cluster in a way similar to what's explained here

- [Multipass VM][multipass]. Alternative VM setup with no NixOS in
  sight. You can also use this as a dev env or as a baseline to
  install MicroK8s on Ubuntu.

Either way, before going ahead, make sure you've [set up properly
your local dev env][dev-env].




[admin-access]: ../cluster-admin-access.md
[dev-env]: ../dev-env.md
[k8s-baseline]: ./k8s-baseline.md
[mesh]: ./mesh.md
