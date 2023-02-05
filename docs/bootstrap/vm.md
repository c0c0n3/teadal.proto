Bootstrapping a dev node
------------------------
> Build a fully-fledged, one-node K8s cluster in under 20 mins.

We're going to build a node to host our Teadal cloud stack. This base
machine packs a fully-fledged, one-node K8s cluster (yea, that's a bit
of an oxymoron) we can later use to host the rest of our cloud stack—Istio
& add-ons, Argo CD, etc. This kind of setup is okay for devs, but
obviously not suitable for ops at scale.


### Outcome

At the end of the procedure detailed below, you should end up with
a NixOS machine having

- All the services you'd expect in a full-blown K8s cluster.
  Namely: apiserver, controllerManager, scheduler, addonManager,
  kube-proxy, etcd, flannel, easyCerts and coredns. These are
  systemd service you can manage in the usual way with `systemctl`,
  `journalctl`, etc.
- Broadened K8s node port range. So you'll be able to expose any
  K8s node port you might use.
- Privileged K8s containers. apiserver will happily spawn privileged
  containers for you.
- No firewall. You can turn it on if you really want it, but most
  likely it's not needed for a dev box?
- Tools for K8s stack dev & ops: `kubectl`, `istioctl`, `argocd`
  `kustomize` and `helm`.
- An admin user named `admin` with a password of `abc123`. (You
  can change the password later.) This user is also configured
  to have admin access to the K8s services, so e.g. `kubectl`
  works out of the box.
- Remote access through SSH.
- Basic Linux sys admin tools like `hwinfo`, `tcpdump`, etc. You
  can find the full list in our `cli-tools` Nix package. Plus,
  Bash completion and Emacs (built without X11 deps) as a default
  system editor.


### Hardware

Ideally, you have a box with at least 4 CPUs, 16GB of RAM and 100GB
SSD storage. But you can get away with just 2 CPUs, 4GB RAM and 50GB
storage. Surely you can use a VM with the same specs instead of bare
metal. In fact, that's what we do in the examples below.


### NixOS installation

#### Booting the ISO image
Download the NixOS 22.11 image and boot it on the designated victim,
i.e. your target installation machine. How to do that exactly depends
on your hardware—have a look at the NixOS manual for the details. For
the sake of having a concrete example, we use Qemu—[our Nix shell][dev-env]
comes with the exact Qemu version we used.

First create a 50GB disk—100GB would be better if you have enough
room on your box.

```bash
$ qemu-img create -f qcow2 "devm.img.qcow2" 50G
```

Then make Qemu boot from the NixOS ISO image file

```bash
$ qemu-system-x86_64 \
    -cdrom nixos-minimal-22.11.1895.ab1254087f4-x86_64-linux.iso \
    -drive "file=devm.img.qcow2,format=qcow2" \
    -machine q35,vmport=off -cpu host -smp 2 -m 4G -accel hvf
```

Notice the above command assumes the host has an x86_64 architecture
with at least two cores and 4GB of RAM to allocated to the VM. Also,
it asks Qemu to piggyback on MacOS's Hypervisor framework for hardware
acceleration. You'll have to change those parameters depending on your
host architecture and OS—e.g. on a Linux ARM64 box with KVM compiled
into the kernel, the command should be `qemu-system-aarch64 -enable-kvm`
followed by the other params above except for `-accel hvf`.

Make yourself root before running the commands in the sections below.

```bash
$ sudo -i
```

#### Partitioning
Partition your storage using a master boot scheme with one primary
bootable partition of at least 30GB to host Grub and the whole OS.
Then add two extra partitions for cloud storage—later on, we'll bring
in DirectPV to make those partitions available to K8s.

```bash
$ lsblk                              # should list /dev/sda
$ parted -a optimal /dev/sda
(parted)  mklabel msdos              # master boot record
(parted)  mkpart primary 1MB 30GB    # Grub + OS partition
(parted)  set 1 boot on              # make it bootable
(parted)  mkpart primary 30GB 40GB   # a cloud storage partition
(parted)  mkpart primary 40GB 50GB   # another cloud storage partition
(parted)  q                          # quit
```

Now format the boot/OS partition with ext4.

```bash
$ mkfs.ext4 -L nixos /dev/sda1
```

#### Installing a bare-bones NixOS
Mount the `nixos` disk on `/mnt` and generate NixOS's initial config

```bash
$ mount /dev/disk/by-label/nixos /mnt
$ nixos-generate-config --root /mnt
```

Then tweak the generated config

```bash
$ nano /mnt/etc/nixos/configuration.nix
```

```nix
boot.loader.grub.device = "/dev/sda";    # double-check it's the right disk
networking.hostName = "devm";            # pick a hostname
time.timeZone = "Europe/Amsterdam";      # set your time zone
```

Finally do the actual install, enter the root password when prompted
and then power off the box.

```bash
$ nixos-install
#  <enter root password>
$ poweroff
```

#### Installing the K8s stack
All is left to do now is, wait for it, install and configure K8s.
Mission? Luckily, we've got a Nix Flake to take care of all that!

Power on your NixOS box, e.g.

```bash
$ qemu-system-x86_64 \
    -machine q35,vmport=off -cpu host -smp 2 -m 4G -accel hvf \
    -nic user  \
    devm.img.qcow2
```

Notice, like the one earlier, this is again a Qemu command that's
specific to a MacOS x86_64 host. You'll have to tweak it according
to your host architecture/OS.

After logging in as root, cd to `/etc/nixos`, download our dev VM
Nix Flake and possibly tweak it

```bash
$ cd /etc/nixos
$ curl -o flake.nix https://raw.githubusercontent.com/c0c0n3/teadal.proto/main/nix/nodes/devm/initial-flake.nix
$ nano flake.nix
```

The Flake installs the Teadal OS base config and sets up a one-node
K8s cluster. There's two things you might need to tweak in that file:
system architecture and swap memory. The default system architecture
is `x86_64-linux`, but if you're e.g. on ARM64, you should set it to
`aarch64-linux` instead. Swap defaults to 4GB, change it if that
doesn't suit you.

Now rebuild NixOS with this Flake

```bash
$ nixos-rebuild switch --flake .#devm
```

There might be some transient errors with some of the K8s services
right after installation, but they should go away after a reboot.
Also, after rebooting run

```bash
$ nix-collect-garbage -d
```

to get rid of unused packages in the Nix store and save disk space.


### Sanity check

At this point your freshly minted box should be ready for our cloud
adventure! Let's run a couple of smoke tests to make sure :-)

Boot the machine, forwarding local port 10022 to port 22 on the
machine. (Not needed if you installed on a separate box.) Here's
how to do that for the example Qemu VM we've built

```bash
$ qemu-system-x86_64 \
    -machine q35,vmport=off -cpu host -smp 2 -m 4G -accel hvf \
    -display none \
    -nic user,hostfwd=tcp::10022-:22 \
    devm.img.qcow2
```

Open a terminal on your local host and SSH into the NixOS box as
`admin`, using `abc123` as password:

```bash
$ ssh admin@localhost -p 10022
#     ^ tweak the command if the NixOS box is remote.
```

Now check the various K8s services are happy e.g. `systemctl status`.
Then have some fun with `kubectl`

```bash
$ kubectl get event
$ kubectl get pod --all-namespaces
```




[dev-env]: ../dev-env.md
