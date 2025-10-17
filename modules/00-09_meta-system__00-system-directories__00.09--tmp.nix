# 00.09 System Directory: /tmp
# JDD symlink to temporary files
{ inputs, ... }:

{
  flake.nixosModules."00.09-tmp" = { config, lib, pkgs, ... }: {
    systemd.tmpfiles.rules = [
      "L+ /jdd/00-system/00.09--tmp - - - - /tmp"
    ];
  };
}
