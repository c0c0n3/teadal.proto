Cluster bootstrap
-----------------
> ...or the Teadal big-bang event.

We need to put together a K8s baseline installation we can later
use to host our cloud stack—Istio & add-ons, Argo CD, etc. The
outcome should be a fully-fledged, K8s `1.27.1` cluster. Also,
each node should have an OS base we can fully manage remotely through
config files in a Git repo. Plus, we should be able to reproduce
the **exact same stack** on dev boxes to keep "works on my machine"
accidents from happening.

There's more than one way to skin a cat. To get the ball rolling we
decided to use [Nix & friends][nix]. Nix has [huge advantages][nix-explore]
over other tech stacks you could use to do GitOps as well as building
& managing a K8s cluster. But Nix isn't everyone's cup of tea. So it
goes without saying that we can ditch it going forward if the team
doesn't like it and use something else instead-surely there's plenty
to choose from, e.g. Terraform, Ansible, etc.

Anyhoo, here's what our procedures to bootstrap dev & cluster nodes
look like at the moment.

- [Bootstrapping a dev node][vm]. Read this to build a fully-fledged,
  one-node K8s cluster from scratch in under 20 mins.
- [Bootstrapping a cluster node][node]. How you'd set up a K8s node
  in an actual multi-node cluster.

Keep in mind we could streamline these procedures even more if we
built custom NixOS images-see [#3][gh#3]. In that case, you'd be
able to bootstrap a fully-fledged node in three simple steps: boot
the image, partition the storage, run `nixos-install`. If we go down
that road, then we can also build AWS, GCE, etc. images basically at
no additional dev cost.




[gh#3]: https://github.com/c0c0n3/teadal.proto/issues/3
[nix]: https://nixos.org/
[nix-explore]: https://nixos.org/explore.html
[node]: ./node.md
[vm]: ./vm.md
