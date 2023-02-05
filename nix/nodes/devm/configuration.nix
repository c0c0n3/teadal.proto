{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda";

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };
    "/directpv-1" = {
      device = "/dev/disk/by-label/directpv-1";
      fsType = "ext4";
    };
    "/directpv-2" = {
      device = "/dev/disk/by-label/directpv-2";
      fsType = "ext4";
    };
  };

  networking.hostName = "devm";
  time.timeZone = "Europe/Amsterdam";
  system.stateVersion = "22.11";

  # services.qemuGuest.enable = true;
  teadal.devm.enable = true;
  teadal.swapfile = {
    enable = true;
    size = 4096;
  };
}
