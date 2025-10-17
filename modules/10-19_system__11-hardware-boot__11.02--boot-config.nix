# 11.02 Boot Configuration (Flake-Parts Module)
# Systemd-boot with EFI support
{ inputs, ... }:

{
  # Contribute boot configuration as a nixosModule
  flake.nixosModules."11.02-boot-config" = { config, lib, pkgs, ... }: {
    # Bootloader configuration
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # Enable kernel modules needed for Android containers (Waydroid/Redroid)
    boot.extraModulePackages = with config.boot.kernelPackages; [ pkgs.linuxPackages.v4l2loopback ];
    boot.kernelModules = [ "binder_linux" "ashmem_linux" ];
  };
}