Teadal mesh bootstrap
---------------------
> First rollout!

So we've got a K8s cluster and now we've got to roll out our own
cloud stack. We're going to deploy a bare-bones Istio mesh and then
bootstrap Argo CD which will complete the initial deployment with
all the goodies we've got in our repo. Past this initial bootstrap
phase, Argo CD will pick up any changes to our repo and deploy them
to implement the newly declared cluster state.


### Setting the stage

You should have a K8s `1.27` cluster up and running and a shell with
a `KUBECONFIG` env var pointing to the admin creds for your cluster.

The commands in the sections below assume you have

* cloned our repo
* started a Nix shell: `cd teadal.proto/nix && nix shell`
* made `teadal.proto/deployment/` your current dir.


### External network

The mesh we're going to roll out needs to be connected to some ports
on the external network. Clients on the external network hit port `80`
to access HTTP services. The Istio gateway uses a K8s node port to
accept incoming traffic on port `80` and route it to the destination
service inside the mesh. The Istio gateway also has a `5432` node port
to let external clients interact with the Postgres DB inside the mesh.
Finally admins will want to SSH into cluster nodes so port `22` should
be open too as well as port `6443` which is the K8s API endpoint admin
tools like `kubectl` should connect to.

How you actually make these ports available to processes running
outside the mesh really depends on your setup. In the most trivial
case where your cluster is made up by a single node and that node
is directly connected to the Internet, all you need to do is open
those ports in the firewall, if you have a one, or do nothing if
there's no firewall. In a public cloud scenario, e.g. AWS, you
typically have an admin console that lets you easily make ports
available to clients out in the interwebs.


### K8s storage

We'll start off with local storage for now since we've only got one
node in the cluster. Later on, when we add more nodes, we'll switch
over to distributed storage backed by local disks on each node. (We
set up DirectPV for that, but we could also use Longhorn or something
else.)

We'll create 4 PVs of 5GB each. Ideally they should be backed by
disk partitions, but we'll cheat a bit and create dirs straight into
the `/mnt` directory. (For the record, here's the proper way of
doing [this sort of thing][proper-ls].) Anyhoo, let's go on with
creating the dirs. SSH into the target node, then

```bash
$ sudo mkdir -p /data/d{1..4}
$ sudo chmod -R 777 /data
```

Now get back to your Teadal repo on your local machine and run

```bash
$ kustomize build mesh-infra/storage/pv/local/devm/ | kubectl apply -f -
```


### K8s secrets

```bash
$ kubectl apply -f mesh-infra/argocd/namespace.yaml
```

Edit the K8s Secret templates in `mesh-infra/security/secrets` to
enter the passwords you'd like to use. Then install them in the cluster

```bash
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

Notice that Argo CD creates an initial secret with an admin user of
`admin` and randomly generated password on the first deployment. To
grab that password, run

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
        -o jsonpath="{.data.password}" | base64 -d && echo
```

You can use it if you get in trouble during the bootstrap procedure,
but keeping it around is like an accident waiting to happen. So you
should definitely zap it as soon as you've managed to log into Argo
CD with the password you entered in our secret. To do that, just

```bash
$ kubectl -n argocd delete secret argocd-initial-admin-secret
```




[proper-ls]: https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner/blob/master/docs/operations.md
