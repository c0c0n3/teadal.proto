Teadal cloud proto
------------------
> ...still very much a work in progress!

Here's some initial dev notes to explain part of what's been done.

- [Cluster bootstrap][bootstrap]. Assembling a fully-fledged K8s
  `1.26.0` cluster we can later use to host our cloud stack—Istio
  & add-ons, Argo CD, etc. We use GitOps at the OS-level too, managing
  nodes remotely through config files in a Git repo. Plus, we can
  reproduce the **exact same stack** on dev boxes to keep "works
  on my machine" accidents from happening.
- [Cluster admin access][admin-access]. Setting up admin access to
  your freshly minted K8s cluster.
- [OS deployment][os-depl]. Doing GitOps at the OS-level. Keep the
  code that defines OS deployments in a git repo and then apply it
  to a remote set of machines to update their configuration, packages,
  services, etc. The git repo is the single source of truth, the remote
  machines reflect the deployment state declared in the repo.
- [Dev env][dev-env]. Setting up basic tools to develop and manage
  the Teadal cluster. One-liner install with a virtual env that doesn't
  mess up your box.
- Teadal cloud bootstrap. Setting up Argo CD pipelines to deploy and
  manage the Teadal cloud services and supporting K8s resources.




[admin-access]: ./cluster-admin-access.md
[bootstrap]: ./bootstrap/README.md
[dev-env]: ./dev-env.md
[os-depl]: ./os-deployment.md