Multipass VM
------------
> ...if you hate Nix, try this instead :-)

If Nix isn't your cup of tea, as a developer you can still easily
spin up a VM to run the Teadal cloud. Not as flexible, reproducible,
etc. as Nix/NixOS but it should be compatible.

In fact, the Teadal cloud stack should work on any decently set up
K8s `1.27` cluster base. So what we're going to do here is spin up
a Multipass VM and install K8s `1.27` in it.


### Create the Multipass VM

After installing Multipass, start an Ubuntu `22.04` VM with at least
2 CPUs, 4GB of RAM and 50GB disk—if you can up the CPU count and give
it more RAM it'd be much better though.

```bash
$ multipass launch --name teadal --cpus 2 --memory 4G --disk 50G 22.04
```

Now shell into the freshly minted system

```bash
$ multipass shell teadal
```


### Install MicroK8s

We'll use [MicroK8s][mk8s] as a cluster manager and orchestration.
Install MicroK8s (upstream Kubernetes `1.27`)

```bash
$ sudo snap install microk8s --classic --channel=1.27/stable
```

Add yourself to the MicroK8s group to avoid having to `sudo` every
time your run a `microk8s` command

```bash
$ sudo usermod -a -G microk8s $(whoami)
$ newgrp microk8s
```

and then wait until MicroK8s is up and running

```bash
$ microk8s status --wait-ready
```

Finally bolt on DNS and local storage

```bash
$ microk8s enable dns
$ microk8s enable hostpath-storage
```

Wait until all the above extras show in the "enabled" list

```bash
$ microk8s status
```

##### Notes
- *Istio*. Don't install Istio as a MicroK8s add-on, since MicroK8s
  will install an old version!
- *Storage*. MicroK8s comes with its own storage provider
  (`microk8s.io/hostpath`) which the storage add-on enables
  as well as creating a default K8s storage class called
  `microk8s-hostpath`.


Now we've got to [broaden MicroK8s node port range][mk8s.port-range].
This is to make sure it'll be able to expose any K8s node port we're
going to use.

```bash
$ nano /var/snap/microk8s/current/args/kube-apiserver
# add this line
# --service-node-port-range=1-65535

$ microk8s stop
$ microk8s start
```


### Setting up K8s admin access

Now let's set up K8s admin access so we can manage the cluster from
outside the VM.

Copy out the K8s admin creds

```bash
$ cat /var/snap/microk8s/current/credentials/client.config
```

save them to a local file outside the VM and replace the IP address
of the `server` URL with that of your Multipass VM, e.g.

```yaml
server: https://192.168.64.28:16443
```

Run the following command outside the VM to grab the IP address

```bash
$ multipass info teadal
```

Finally, export `KUBECONFIG` so `kubectl`, `istioctl` and friends
know where the cluster is

```bash
$ export KUBECONFIG=/path/to/your/copy/of/client.config
```




[mk8s]: https://microk8s.io/
[mk8s.port-range]: https://github.com/ubuntu/microk8s/issues/284
