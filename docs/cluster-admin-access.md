Cluster admin access
--------------------
> Keep it safe!

There's many ways you can set up admin access to your K8s cluster.
We'll look at two here—ask the interwebs for more.

- SSH into a cluster node. As part of our OS setup, the `admin`
  user has admin access (pun intended) to K8s.
- Configure local access from your box. Can be convenient, but
  shouldn't be used in prod scenarios.


### Access through SSH

Our NixOS config comes with a built-in `admin` user. This user,
like `root` has admin access to the K8s cluster through `kubectl`.
Our NixOS config also comes with an SSH daemon `admin` can use for
remote logins. So all you need to do is start an SSH session from
your box to a cluster node, logging in as `admin`. Once you're in,
have fun with `kubectl`.

Here's an example where we use the dev VM. For the sake of argument,
say you started the dev VM forwarding local port `10022` to the VM
port `22` (SSH)

```bash
$ qemu-system-x86_64 \
    -machine q35,vmport=off -smp 4 -m 8G \
    -drive file=devm.img.raw,format=raw,if=virtio \
    -nic user,model=virtio-net-pci,hostfwd=tcp::10022-:22
```

Now log in through SSH and run any `kubectl` command you fancy

```bash
$ ssh admin@localhost -p 10022
[admin@devm:~]$ kubectl get pod -A
```


### Direct access from your box

**WARNING**: only use the setup below for the dev VM or your own
dev cluster, never in a prod scenario!!

Did you read the warning? Cool, let's move on :-)

Since you can log on any node as admin, you can copy out the K8s
config over to your box and make your local `kubectl` use that
config to connect to the cluster. Let's see how to do that with
the dev VM—for a remote cluster you'd do pretty much the same.

Start the dev VM forwarding both SSH and K8s ports. Here's how to
do that

```bash
$ qemu-system-x86_64 \
    -machine q35,vmport=off -smp 4 -m 8G \
    -drive file=devm.img.raw,format=raw,if=virtio \
    -nic user,model=virtio-net-pci,hostfwd=tcp::10022-:22,hostfwd=tcp::16443-:6443
```

Notice your local port `16443` gets forwarded to `6443` which is
where the K8s API runs inside the VM.

Create a `k8s` dir on your local machine to hold the k8s you'll use
later to connect to the cluster. Now SSH into the cluster node and
print out the K8s config

```bash
$ ssh admin@localhost -p 10022
[admin@devm:~]$ kubectl config view --raw
```

Then copy over the referenced key files to your local `k8s` dir,
keeping the same file names. e.g.

```bash
$ cd k8s
$ scp -P 10022 admin@localhost:/var/lib/kubernetes/secrets/ca.pem ./
$ scp -P 10022 admin@localhost:/var/lib/kubernetes/secrets/cluster-admin.pem ./
$ scp -P 10022 admin@localhost:/var/lib/kubernetes/secrets/cluster-admin-key.pem ./
```

Finally, create a `config.yaml` file with this content

```yaml
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority: ca.pem
    server: https://localhost:16443
  name: teadal-devm
contexts:
- context:
    cluster: teadal-devm
    user: cluster-admin
  name: teadal-devm
current-context: teadal-devm
users:
- name: cluster-admin
  user:
    client-certificate: cluster-admin.pem
    client-key: cluster-admin-key.pem
```

and then

```bash
export KUBECONFIG=/path/to/your/k8s/config.yaml
```

Now you should be able to run `kubectl` on your local host, outside
the VM.
