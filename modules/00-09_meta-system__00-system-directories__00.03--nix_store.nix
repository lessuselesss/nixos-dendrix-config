# 00.03 System Directory: /nix/store
# JDD symlink to immutable package store
{ inputs, ... }:

{
  flake.nixosModules."00.03-nix-store" = { config, lib, pkgs, ... }: {
    systemd.tmpfiles.rules = [
      "L+ /jdd/00-system/00.03--nix-store - - - - /nix/store"
    ];
  };
}
