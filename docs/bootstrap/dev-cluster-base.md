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
  systemd services you can manage in the usual way with `systemctl`,
  `journalctl`, etc.
- Broadened K8s node port range. So you'll be able to expose any
  K8s node port you might use.
- Privileged K8s containers. apiserver will happily spawn privileged
  containers for you.
- No firewall. You can turn it on if you really want it, but most
  likely it's not needed for a dev box?
- Tools for K8s stack dev & ops: `kubectl` with `directpv` and `minio`
  plugins, `istioctl`, `argocd`. These tools are available and configured
  system-wide to work with the K8s cluster. Plus, if you run `nix shell`
  with our Flake, you get extra tools like `kustomize` and `helm`. You
  can find the full list in the [Dev env][dev-env] page.
- An admin user named `admin` with a password of `abc123`. (You
  can change the password later.) This user is also configured
  to have admin access to the K8s services, so e.g. `kubectl`
  works out of the box.
- Remote access through SSH.
- Basic Linux sys admin tools like `hwinfo`, `tcpdump`, etc. You
  can find the full list in our `cli-tools` Teadal Nix package. Plus,
  Bash completion and Emacs (built without X11 deps) as a default
  system editor.


### Hardware

Ideally, you have a box with at least 4 CPUs, 16GB of RAM and 100GB
SSD storage. But you can get away with just 2 CPUs, 4GB RAM and 50GB
storage. Surely you can use a VM with the same specs instead of bare
metal. In fact, that's what we do in the examples below where we use
Qemu to simulate a basic x86-64 server.

For an explanation of the Qemu commands we use below, have a read
through our [Qemu snippets][qemu-snippets]. There you'll also find
ways to customise those commands to e.g. run VMs at near native speed
depending on your host—e.g. MacOS on Apple silicon, MacOS on x86-64,
Linux on ARM64, etc.


### NixOS installation

After provisioning the hardware, you install our NixOS/K8s stack.
At the moment we have a semi-automated procedure to do that:

1. Log onto the target machine.
2. Boot the NixOS ISO image.
3. Partition the disk.
4. Install a bare-bones NixOS.
5. Install our K8s/NixOS stack.

We'll demo below how to do all this with the example Qemu VM.

Keep in mind we could automate all this so after provisioning the
box, all you'd have to do is run a single command which would take
care of steps (1) through (5) above. All we need to do is package
our Flake into [NixOS Anywhere][nixos-anywhere]. This would be a
life-saver for cloud deployments with dozens of machines, but for
now it's not really needed since we've got just a couple of boxes
to manage. So I'd rather not introduce yet another tool.

#### Booting the ISO image
Download the NixOS 23.05 image and boot it on the designated victim,
i.e. your target installation machine. How to do that exactly depends
on your hardware—have a look at the NixOS manual for the details. For
the sake of having a concrete example, we use Qemu—[our Nix shell][dev-env]
comes with the exact Qemu version we used.

First create a 50GB disk—100GB would be better if you have enough
room on your box. For best performance, you should create a raw disk
like so

```bash
$ qemu-img create -f raw devm.img.raw 50G
```

Now make Qemu boot from the NixOS ISO image file

```bash
$ qemu-system-x86_64 \
    -machine q35,vmport=off -smp 4 -m 8G \
    -cdrom nixos-minimal-23.05.1156.ad157fe26e7-x86_64-linux.iso \
    -drive file=devm.img.raw,format=raw,if=virtio \
    -nic user,model=virtio-net-pci
```

Notice the above command starts a Qemu x86_64 machine and should work
even if your host isn't x86_64—e.g. you're on MacOS Apple silicon.
Ideally though, your host should have more than 4 cores and 8GB of
RAM. If that's not the case, tweak the above `-smp` and `-m` params
according to your actual hardware resources.

Make yourself root before running the commands in the sections below.

```bash
$ sudo -i
```

#### Partitioning
Partition your storage with one bootable ext4 partition of at least
30GB to host the OS. Again, how to do that exactly depends on your
hardware—have a look at the NixOS manual for the details.

In our running example, we partition our storage using a master boot
scheme with one primary bootable partition spanning the entire drive
to host Grub and the whole OS. You can always add disks later which
you can use for cloud storage. If you use DirectPV, then the DirectPV
driver should be able to auto-magically pick up any disks or partitions
you add and make them available to K8s.

Anyway, on with our Qemu example.

```bash
$ lsblk                              # should list /dev/vda
$ parted -a optimal /dev/vda
(parted)  mklabel msdos              # master boot record
(parted)  mkpart primary 1MB 100%    # Grub + OS partition
(parted)  set 1 boot on              # make it bootable
(parted)  q                          # quit
```

Now format the boot/OS partition with ext4.

```bash
$ mkfs.ext4 -L nixos /dev/vda1
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
boot.loader.grub.device = "/dev/vda";    # double-check it's the right disk
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
    -machine q35,vmport=off -smp 4 -m 8G \
    -drive file=devm.img.raw,format=raw,if=virtio \
    -nic user,model=virtio-net-pci
```

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

We're going to SSH into the box. Here's how to do that for the example
Qemu VM we've built. Boot the machine, forwarding local port 10022
to port 22 on the machine.

```bash
$ qemu-system-x86_64 \
    -machine q35,vmport=off -smp 4 -m 8G \
    -drive file=devm.img.raw,format=raw,if=virtio \
    -nic user,model=virtio-net-pci,hostfwd=tcp::10022-:22
```

Open a terminal on your local host and SSH into the NixOS box as
`admin`, using `abc123` as password:

```bash
$ ssh admin@localhost -p 10022
#     ^ tweak the command if the NixOS box is remote.
```

If you installed on another box or in the cloud, you'd replace the
host and port above accordingly.

Now check the various K8s services are happy e.g. `systemctl status`.
Then have some fun with `kubectl`

```bash
$ kubectl get event -A
$ kubectl get pod -A
```




[dev-env]: ../dev-env.md
[nixos-anywhere]: https://github.com/numtide/nixos-anywhere
[qemu-snippets]: ../qemu.md
