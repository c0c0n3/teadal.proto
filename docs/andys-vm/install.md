Andy's Azure VM
---------------
> Building a single-node Teadal cluster from scratch.

So we'll be building a single-node Teadal cluster from scratch. Well,
almost from scratch. Andy graciously provided an Azure Ubuntu VM, so
we won't have to provision the hardware and OS ourselves. We'll install
K8s on that VM, then the rest of the Teadal cloud.


### Azure Ubuntu VM

We've got an Azure VM with these specs:

- CPU. Arch: x86_64; Model: Intel(R) Xeon(R) Platinum 8370C CPU @ 2.80GHz;
  Cores: 4.
- RAM. 16GB.
- Storage.
  - Boot/OS disk. 32GB (`/dev/sdb`).
  - Stock disk. 320GB (`/dev/sda`, one `ext4`-formatted partition mounted
    on `/mnt`).
  - Extra disks. 3 x 20GB raw disks (`/dev/sdc`, `/dev/sdd`, `/dev/sde`).
- Network. External ports: `22` (SSH), `80` (HTTP), `5432` (Postgres),
  `16443` (K8s).
- OS. Ubuntu `22.04.2` LTS (Kernel: Linux 5.15.0-1041-azure).

You'll need to ask Andy to set up SSH access for you. This is what
I've done. First off, generate your SSH identity keys. Here's how
to do that on MacOS with the `ed25519` algo

```bash
$ ssh-keygen -t ed25519 -C 'andrea.falconi@martel-innovate.com'
```

or the RSA algo

```bash
$ ssh-keygen -t rsa -b 4096 -C 'andrea.falconi@martel-innovate.com'
```

Give the keys to Andy, he'll give you back an access key (e.g.
`tv-teadal_key.pem`) you should store in a **safe** place and
restrict access to yourself only (`chmod 600 tv-teadal_key.pem`).
Now you should be able to SSH into the VM

```bash
$ ssh -i tv-teadal_key.pem teadal@20.4.3.245
```

#### NOTE
1. Root partition size. It's only 30GB, so we shouldn't clog it
up with extra software. MicroK8s (see below) keeps everything
(including Docker images) under `/var` by default so we might
have to make it use another ephemeral storage location at some
point. (e.g. by making `--root-dir` in `/var/snap/microk8s/current/args/kubelet`
point to a dir in `/mnt` where we've got more than 300GB.)


### MicroK8s

#### Install
Same as in Multipass VM / Install MicroK8s.

But do **not** enable `hostpath-storage`. As noted earlier, we don't
have much room in the root partition. So if we enable it, we should
also configure it to use a different partition. Too much of a pain.
Besides this plugin is deprecated.


#### K8s admin access
Same as in Multipass VM / Setting up K8s admin access.

But to use `kubeclt` from your box, you'll have to tweak the K8s
config you copied out from the VM to your box.
- comment out `certificate-authority-data`
- add this line below it: `insecure-skip-tls-verify: true`


### Nix

Install Nix on your box (not on Andy's VM) as explained in Dev Env.
Nix installs all its packages in `/nix` and it's a bit of a mission
to use an alternate directory. As noted earlier, we shouldn't clog
up the VM's root partition. Besides, Nix isn't really needed on the
VM.


### Setting the stage

Same as in Teadal cloud bootstrap.


### K8s storage

We'll start off with local storage for now since we've only got one
node in the cluster. Later on, when we add more nodes, we'll switch
over to distributed storage backed by local disks on each node. (We
set up DirectPV for that, but we could also use Longhorn or something
else.)

We'll create 5 PVs of 10GB each. Ideally they should be backed by
disk partitions, but we'll cheat a bit and create dirs straight into
the `/mnt` directory. (For the record, here's the proper way of
doing [this sort of thing][proper-ls].) Anyhoo, let's go on with
creating the dirs. SSH into Andy's VM, then

```bash
$ sudo mkdir -p /mnt/k8s-data/d{1..5}
$ sudo chmod -R 777 /mnt/k8s-data
```

Now get back to your Teadal repo on your local machine and run

```bash
$ kustomize build mesh-infra/storage/pv/local/tv-teadal/ | kubectl apply -f -
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

Same as in Teadal cloud bootstrap.


### Argo CD

Same as in Teadal cloud bootstrap.




[proper-ls]: https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner/blob/master/docs/operations.md
