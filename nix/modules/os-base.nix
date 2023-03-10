#
# A simple system base with CLI tools, Emacs and admin user.
# This module installs:
#
# * Emacs (built w/o X11 deps)
# * Bash completion and a given set of CLI tools
# * Nix Flakes extension
#
# and then makes:
#
# * Emacs the default editor system-wide (`EDITOR` environment variable)
#
# Finally it creates an admin user with username 'admin' and sets the
# given hashed passwords for both the admin and root users.
#
{ config, lib, pkgs, ... }:

with lib;
with types;
let
  # Default password of 'abc123' generated w/ `mkpasswd`.
  # WARNING: convenience for dev VMs, never use in the cluster!
  pwd = "$6$DmW6Owb/Swuzs7$DKca.vHGUP3bTz/G5vae4/egALZVVdsGdkhzISU11ZsFy2jmMVkZtIwTbNzK5cau9AOmb2B4LTd6BxcOKR1oW1";
in {

  options = {
    teadal.base.enable = mkOption {
      type = bool;
      default = false;
      description = ''
        Enable it to install this system base.
      '';
    };
    teadal.base.cli-tools = mkOption {
      type = listOf package;
      default = [];
      description = ''
        CLI tools to install system-wide.
      '';
    };
    teadal.base.root-pwd = mkOption {
      type = str;
      default = pwd;
      description = ''
        The root user's password as generated by `mkpasswd`.
      '';
    };
    teadal.base.admin-pwd = mkOption {
      type = str;
      default = pwd;
      description = ''
        The admin user's password as generated by `mkpasswd`.
      '';
    };
  };

  config = let
    enabled = config.teadal.base.enable;
    tools = config.teadal.base.cli-tools;
    admin-pwd = config.teadal.base.admin-pwd;
    root-pwd = config.teadal.base.root-pwd;
  in (mkIf enabled
  {
    # Enable Flakes.
    nix = {
      package = pkgs.nixFlakes;
      settings.experimental-features = [ "nix-command" "flakes" ];
    };

    # Install Emacs and make it the default editor system-wide.
    # Also install the given CLI toos and enable Bash completion.
    environment.systemPackages = [ pkgs.emacs-nox ] ++ tools;
    environment.variables = {
      EDITOR = "emacs";    # NOTE (1)
    };
    programs.bash.enableCompletion = true;

    # Create admin user w/ name='admin' and given password.
    # Also set the given root password.
    users.users.admin = {
      isNormalUser = true;
      group = "users";
      extraGroups = [ "wheel" ];
      hashedPassword = admin-pwd;
    };
    users.users.root.hashedPassword = root-pwd;
  });

}
# NOTE
# ----
# 1. Command Paths. Should we use absolute paths to the Nix derivations?
# Seems kinda pointless b/c programs added to systemPackages will be in
# the PATH anyway...
