{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  networking.hostName = "devm";
  time.timeZone = "Europe/Amsterdam";
  system.stateVersion = "23.05";

  # services.qemuGuest.enable = true;
  teadal.devm.enable = true;
  teadal.swapfile = {
    enable = true;
    size = 4096;
  };
}
