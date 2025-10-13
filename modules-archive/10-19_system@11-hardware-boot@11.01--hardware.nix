# 11.01 Hardware Configuration
# System hardware configuration for x86_64-linux platform
{ config, lib, pkgs, ... }:

{
  # Boot hardware modules
  boot.initrd.availableKernelModules = [ 
    "xhci_pci" 
    "thunderbolt" 
    "vmd" 
    "nvme" 
    "usb_storage" 
    "sd_mod" 
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # File systems
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/fdad2401-0d31-47f5-a7da-87561e00e88c";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/21FE-D958";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [ ];

  # Platform configuration
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}