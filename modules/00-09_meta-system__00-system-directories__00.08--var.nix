# 00.08 System Directory: /var
# JDD symlink to variable data and state
{ inputs, ... }:

{
  flake.nixosModules."00.08-var" = { config, lib, pkgs, ... }: {
    systemd.tmpfiles.rules = [
      "L+ /jdd/00-system/00.08--var - - - - /var"
    ];
  };
}
