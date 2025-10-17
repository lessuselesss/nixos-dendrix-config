# 00.04 System Directory: /nix
# JDD symlink to nix system root
{ inputs, ... }:

{
  flake.nixosModules."00.04-nix" = { config, lib, pkgs, ... }: {
    systemd.tmpfiles.rules = [
      "L+ /jdd/00-system/00.04--nix - - - - /nix"
    ];
  };
}
