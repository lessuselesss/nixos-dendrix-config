# 00.05 System Directory: /boot
# JDD symlink to bootloader and kernel
{ inputs, ... }:

{
  flake.nixosModules."00.05-boot" = { config, lib, pkgs, ... }: {
    systemd.tmpfiles.rules = [
      "L+ /jdd/00-system/00.05--boot - - - - /boot"
    ];
  };
}
