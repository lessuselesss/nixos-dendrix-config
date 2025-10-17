# 00.06 System Directory: /root
# JDD symlink to root user home
{ inputs, ... }:

{
  flake.nixosModules."00.06-root" = { config, lib, pkgs, ... }: {
    systemd.tmpfiles.rules = [
      "L+ /jdd/00-system/00.06--root - - - - /root"
    ];
  };
}
