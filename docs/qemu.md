Qemu snippets
-------------
> Copy-paste if you like but don't forget to read up about Qemu!

We use Qemu to simulate cloud nodes. If you're not familiar with
Qemu, here's some copy-paste material along with explanations to
get you going. But you should really read up about Qemu, there's
lots of tutorials out there which are a much better starting point
than what you'll find here. One good resource is the [Arch Linux
Wiki][arch-qemu].


### Creating a disk

Let's create a 50GB disk you can attach to a Qemu VM. You can use
different disk formats, each with its own trade-offs. If you don't
care about space and you want best performance, you should create
a raw disk like so

```bash
$ qemu-img create -f raw devm.img.raw 50G
```

But the above will eat up right away `50GB` from your machine's hard
drive, regardless of how much space the VM is actually going to use.
If you don't mind worse performance, you can use the `qcow2` format
instead which will grow on demand as the VM's OS allocates disk space
and stop growing when all `50GB` have been used up.

```bash
$ qemu-img create -f qcow2 devm.img.qcow2 50G
```

To attach these disks to a VM, pass, respectively these args when
starting a VM

```bash
-drive file=devm.img.raw,format=raw,if=virtio
```

```bash
-drive file=devm.img.qcow2,format=qcow2,if=virtio
```

The `if=virtio` param makes virtio available to the VM's guest which
speeds up disk access. For that to work though, the guest must have
drivers for virtio devices. That's usually the case for Linux, but
take `if=virtio` out if something breaks.

Notice you can attach multiple disks to your VM if you like, e.g.

```bash
...
-drive file=d1.img.raw,format=raw,if=virtio \
-drive file=d2.img.raw,format=raw,if=virtio \
...
```


### Choosing an architecture

You use one of the `qemu-system-<arch>` to start a VM where `<arch>`
identifies a CPU architecture Qemu knows how to handle. For example,
here's a simple command to start a PC-like x86_64 VM with 2 cores,
`4GB` of RAM and attach the raw drive we created earlier

```bash
$ qemu-system-x86_64 \
    -drive file=devm.img.raw,format=raw \
    -machine q35,vmport=off -smp 2 -m 4G
```

Now if your machine isn't x86_64, Qemu will emulate x86_64 for you.
Sure, emulation can be slow. But say you're on an x86_64 MacOS. Then
you can get near native speed by telling Qemu to use the host's CPU
and piggyback on MacOS's Hypervisor framework for hardware acceleration.
To do that, also pass the `-cpu host` and `-accel hvf` options when
starting the VM:

```bash
$ qemu-system-x86_64 \
    -drive file=devm.img.raw,format=raw \
    -machine q35,vmport=off -smp 2 -m 4G -cpu host -accel hvf
```

And what if you wanted to run an ARM machine on Apple silicon? Well,
since the VM's architecture matches the host's and as we saw earlier
MacOS comes with Hypervisor, we can get again near native speed with

```bash
$ qemu-system-aarch64 \
    -drive file=devm.img.raw,format=raw \
    -machine virt,gic-version=3 -smp 2 -m 4G -cpu host -accel hvf
```

Notice we're now using the `qemu-system-aarch64` command instead of
`qemu-system-x86_64` and the `-machine` spec has changed accordingly.
On a Linux ARM64 box with KVM compiled into the kernel, the command
should still be `qemu-system-aarch64` but you'd use `-enable-kvm`
instead of `-accel hvf`.

So to start Qemu, you'll use different commands and parameters depending
on whether you want to emulate an architecture or use the same architecture
as the host, in which case, you'd want to tweak acceleration according
to the capabilities of the host OS.


### Installing an OS

Running any of the previous commands, won't get you very far. Well,
unless the disk you attach contains a bootable OS. But how to install
an OS in the VM?

One simple way is to boot an ISO image and then install the OS from
there onto a drive you attach to the VM. For example, say you want
to build a NixOS x86_64 VM on Apple silicon. Then get the NixOS ISO
matching the VM's architecture, x86_64 in this case, and start Qemu
with the `-cdrom` option pointing to the ISO. Here's an example with
the NixOS 23.05 ISO file.

```bash
$ qemu-system-x86_64 \
    -machine q35,vmport=off -smp 4 -m 8G \
    -cdrom nixos-minimal-23.05.1156.ad157fe26e7-x86_64-linux.iso \
    -drive file=devm.img.raw,format=raw,if=virtio \
    -nic user,model=virtio-net-pci
```

Notice we specified no acceleration options since the host (Apple
silicon) doesn't match the guest (x86_64). Also notice `virtio-net-pci`,
if available, speeds up network access.

For a slightly different example, say you want a NixOS aarch64 VM
on Apple silicon. In this case we can use acceleration and the Qemu
command would be

```bash
$ qemu-system-aarch64 \
    -machine virt,gic-version=3 -smp 4 -m 8G -cpu host -accel hvf \
    -drive if=pflash,format=raw,file=edk2-aarch64-code.fd \
    -cdrom nixos-minimal-23.05.1123.aaef163eac7-aarch64-linux.iso \
    -drive file=devm.img.raw,format=raw,if=virtio \
    -nic user,model=virtio-net-pci \
    -nographic
```

Notice the NixOS ISO is the aarch64 one now. Also we've got to boot
in UEFI mode which is why we attach the OVMF firmware file, i.e.
`edk2-aarch64-code.fd`. You can find this file bundled with the Qemu
instance in our Nix shell, copy it out and change its perms so you
can both read and write it.

```bash
# the commands below will only work **after** you entered our Nix shell
$ ls -al $(dirname $(readlink $(which qemu-system-aarch64)))/../share/qemu | grep edk
$ cp $(dirname $(readlink $(which qemu-system-aarch64)))/../share/qemu/edk2-aarch64-code.fd .
$ chmod 0664 edk2-aarch64-code.fd
```

Finally in this example we're assuming a non-graphical install, so
we pass the `-nographic` option which makes the guest use your terminal.
That's quite handy since you can copy-paste installation commands
straight into the guest.


### Running a VM

How to run a VM after installing the OS? Simple, just get rid of the
`-cdrom` option! Also, you may want to forward some ports from the
host to the guest as in the example belows.

As a first example, we start the NixOS x86_64 VM we created earlier
on Apple silicon.

```bash
$ qemu-system-x86_64 \
    -machine q35,vmport=off -smp 4 -m 8G \
    -drive file=devm.img.raw,format=raw,if=virtio \
    -nic user,model=virtio-net-pci,hostfwd=tcp::10022-:22,hostfwd=tcp::16443-:6443
```

Again notice there's no acceleration since Qemu is emulating x86_64
on Apple silicon. But notice the `hostfwd` params we use to forward
host port `10022` to guest port `22` and host port `16443` to guest
port `6443`.

For a fancier example, let's start the second VM we built earlier.
This is a NixOS aarch64 VM running on Apple silicon, so we specify
acceleration options.

```bash
$ qemu-system-aarch64 \
    -machine virt,gic-version=3 -smp 4 -m 8G -cpu host -accel hvf \
    -drive if=pflash,format=raw,file=edk2-aarch64-code.fd \
    -drive file=devm.img.raw,format=raw,if=virtio \
    -nic user,model=virtio-net-pci,hostfwd=tcp::10022-:22,hostfwd=tcp::16443-:6443 \
    -nographic
```




[arch-qemu]: https://wiki.archlinux.org/title/QEMU
