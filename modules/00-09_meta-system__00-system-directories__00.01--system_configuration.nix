# 00.01 System Directory: /etc
# JDD symlink to applied system configuration
{ inputs, ... }:

{
  flake.nixosModules."00.01-etc" = { config, lib, pkgs, ... }: {
    systemd.tmpfiles.rules = [
      "L+ /jdd/00-system/00.01--etc - - - - /etc"
    ];
  };
}
