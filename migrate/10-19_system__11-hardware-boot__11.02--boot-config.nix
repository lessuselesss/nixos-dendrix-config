# 11.02 Boot Configuration (Flake-Parts Module)
# Systemd-boot with EFI support
{ inputs, ... }:

{
  # Contribute boot configuration as a nixosModule
  flake.nixosModules.boot = { config, lib, pkgs, ... }: {
    # Bootloader configuration
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
  };
}