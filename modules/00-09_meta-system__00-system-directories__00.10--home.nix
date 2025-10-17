# 00.10 System Directory: /home
# JDD symlink to user home directories
{ inputs, ... }:

{
  flake.nixosModules."00.10-home" = { config, lib, pkgs, ... }: {
    systemd.tmpfiles.rules = [
      "L+ /jdd/00-system/00.10--home - - - - /home"
    ];
  };
}
