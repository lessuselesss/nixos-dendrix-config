# 00.00 System Directory: /etc/nixos
# JDD symlink to NixOS source configuration directory
{ inputs, ... }:

{
  flake.nixosModules."00.00-etc-nixos" = { config, lib, pkgs, ... }: {
    # Create JDD symlink structure
    systemd.tmpfiles.rules = [
      "d /jdd 0755 root root -"
      "d /jdd/00-system 0755 root root -"
      "L+ /jdd/00-system/00.00--etc-nixos - - - - /etc/nixos"
    ];
  };
}
