Aarch64 Dev VM
--------------
> How to build one.

Here's some very rough notes about building a QEMU VM where to install
the Flake in this dir. It's an Aarch64 machine we want. The procedure
is pretty much the same as that in the docs for building an x86_64 VM
on MacOS. Same same but different.


### booting

```bash
$ qemu-img create -f raw devm.img.raw 50G
```

```bash
$ qemu-system-aarch64 \
    -machine virt,gic-version=3 -accel hvf -cpu host -smp 4 -m 8192M \
    -drive if=pflash,format=raw,file=edk2-aarch64-code.fd \
    -cdrom img/nixos-minimal-23.05.1123.aaef163eac7-aarch64-linux.iso \
    -drive file=devm.img.raw,format=raw \
    -nographic
```

##### edk2-aarch64-code.fd
- https://wiki.archlinux.org/title/QEMU#Booting_in_UEFI_mode
- file copied from multipass 1.12
- available in nixpkgs.OVMF but broken at the mo.
  problem: it depends on edk2 which depends on llvm 9 which is broken on
  darwin aarch64. managed to build edk2 by overriding llvm 9 w/ llvm 16,
  then passed this edk2 to the OVMF pkg. but OVMF then doesn't build.

```bash
$ sudo -i
```


### partitioning

```bash
$ lsblk

$ parted -a optimal /dev/vdb -- mklabel gpt

$ parted -a optimal /dev/vdb -- mkpart ESP fat32 0% 512MiB
$ parted -a optimal /dev/vdb -- set 1 esp on
$ parted -a optimal /dev/vdb -- name 1 boot

$ parted -a optimal /dev/vdb -- mkpart primary ext4 512MiB 30GiB
$ parted -a optimal /dev/vdb -- name 2 nixos

$ parted -a optimal /dev/vdb -- mkpart primary ext4 30GiB 40GiB
$ parted -a optimal /dev/vdb -- name 3 directpv-1

$ parted -a optimal /dev/vdb -- mkpart primary ext4 40GiB 100%
$ parted -a optimal /dev/vdb -- name 4 directpv-2
```

### formatting

```bash
$ mkfs.fat -F 32 -n boot /dev/vdb1
$ mkfs.ext4 -L nixos /dev/vdb2
```

### mounting

```bash
$ mount /dev/disk/by-label/nixos /mnt
$ mkdir -p /mnt/boot
$ mount /dev/disk/by-label/boot /mnt/boot
```

### nixos

```bash
$ nixos-generate-config --root /mnt
$ nano /mnt/etc/nixos/configuration.nix

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking.hostName = "devm";

$ nixos-install
  <enter root password>
$ poweroff
```

Install the Flake in this dir as explained in the docs.


### running

Run the VM w/ the K8s cluster.

```bash
$ qemu-system-aarch64 \
    -machine virt,gic-version=3 -accel hvf -cpu host -smp 4 -m 8192M \
    -drive if=pflash,format=raw,file=edk2-aarch64-code.fd \
    -drive file=devm.img.raw,format=raw \
    -nographic \
    -nic user,hostfwd=tcp::10022-:22,hostfwd=tcp::16443-:6443
```
