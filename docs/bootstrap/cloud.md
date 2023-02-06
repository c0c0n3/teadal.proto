Teadal cloud bootstrap
----------------------
> First rollout!

So we've got a K8s cluster and now we've got to roll out our own
cloud stack. We're going to deploy a bare-bones Istio mesh and then
bootstrap Argo CD which will complete the initial deployment with
all the goodies we've got in our repo. Past this initial bootstrap
phase, Argo CD will pick up any changes to our repo and deploy them
to implement the newly declared cluster state.

**Important**. If you're using the Multipass VM, skip the "Direct PV"
and "Local storage instead of DirectPV" sections below.


### Setting the stage

You should have a K8s `1.25` cluster up and running and a shell with
a `KUBECONFIG` env var pointing to the admin creds for your cluster.

The commands in the sections below assume you have

* cloned our repo
* started a Nix shell: `cd teadal.proto/nix && nix shell`
* made `teadal.proto/deployment/` your current dir.


### Direct PV

Install K8s CRDs, perms, Direct PV controller, node drivers, etc.

```bash
$ kustomize build mesh-infra/storage/directpv | kubectl create -f -
```

Discover available drives we can have Direct PV manage. The example
output below refers to the dev VM where we left two partitions empty
for Direct PV to use.

```bash
$ kubectl directpv drives ls
 DRIVE      CAPACITY  ALLOCATED  FILESYSTEM  VOLUMES  NODE  ACCESS-TIER  STATUS
 /dev/sda2  9.3 GiB   -          -           -        devm  -            Available
 /dev/sda3  9.3 GiB   -          -           -        devm  -            Available
```

Make Direct PV manage the drives listed as "Available" on each node.

```bash
$ kubectl directpv drives format --drives /dev/sda2,/dev/sda3 --nodes devm
                        # ^ pass in --force if the drive is already formatted
```

Check the status of the drives you formatted eventually transitions
to "Ready"—it might take a few secs.

```bash
$ kubectl directpv drives ls
 DRIVE      CAPACITY  ALLOCATED  FILESYSTEM  VOLUMES  NODE  ACCESS-TIER  STATUS
 /dev/sda2  4.7 GiB   -          xfs         -        devm  -            Ready
 /dev/sda3  4.7 GiB   -          xfs         -        devm  -            Ready
```


### Local storage instead of DirectPV

TODO. have a look at the local-storage branch

mkfs.ext4 -L directpv-1 /dev/sda2
mkfs.ext4 -L directpv-2 /dev/sda3

kubectl apply -f mesh-infra/storage/pv/devm.yaml
kustomize build mesh-infra/storage/ | kubectl apply -f -


### Secrets

Edit the K8s Secret templates in `mesh-infra/security/secrets` to
enter the passwords you'd like to use. Then install them in the cluster

```bash
$ kubectl create namespace argocd
$ kustomize build mesh-infra/security/secrets | kubectl apply -f -
```


### Istio

Deploy Istio to the cluster using our own profile

```bash
$ istioctl install -y --verify -f mesh-infra/istio/profile.yaml
```

For now platform infra services (e.g. DBs) as well as app services
(e.g. file transfer UI) sit in K8s' `default` namespace, so tell Istio
to auto-magically add an Envoy sidecar to each service deployed to
that namespace

```bash
$ kubectl label namespace default istio-injection=enabled
```

Notice that you can actually be selective about which services get
an Envoy sidecar, but for now we'll just apply a blanket policy to
keep things simple.


### Argo CD

Argo CD is our declarative continuous delivery engine. Except for
the things listed in this bootstrap procedure, we declare the cluster
state with YAML files that we keep in the `deployment` dir within
our GitHub repo. Argo CD takes care of reconciling the current cluster
state with what we declared in the repo.

For that to happen, we've got to deploy Argo CD and tell it to use
the YAML in our repo to populate the cluster. Our repo also contains
the instructions for Argo CD to manage its own deployment state as
well as the rest of the Teadal platform—I know, it sounds like a dog
chasing its own tail, but it works. So we can just build the YAML to
deploy Argo CD and connect it to our repo like this

```bash
$ kustomize build mesh-infra/argocd | kubectl apply -f -
```

After deploying itself to the cluster, Argo CD will populate it with
all the K8s resources we declared in our repo and so slowly the Teadal
platform instance will come into its own. This will take some time.
Go for coffee.

##### Note
* Argo CD project errors. If you see a message like the one below in
  the output, rerun the above command again — see [#42][boot.argo-app-issue]
  about it.
  > unable to recognize "STDIN": no matches for kind "AppProject" in version "argoproj.io/v1alpha1"
