# 00.07 System Directory: /run/current-system
# JDD symlink to active system generation
{ inputs, ... }:

{
  flake.nixosModules."00.07-run-current-system" = { config, lib, pkgs, ... }: {
    systemd.tmpfiles.rules = [
      "L+ /jdd/00-system/00.07--run-current-system - - - - /run/current-system"
    ];
  };
}
