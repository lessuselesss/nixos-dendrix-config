# 11.01 Hardware Configuration (Flake-Parts Module)
# System hardware configuration for x86_64-linux platform
{ inputs, ... }:

{
  # Contribute to nixosConfigurations by providing a module
  flake.nixosModules."11.01-hardware-config" = { config, lib, pkgs, ... }: {
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

    # File systems - Btrfs with compression
    # CRITICAL: System data lives in btrfs root (subvolid=5), NOT in @ subvolume
    # The @ subvolume is empty and was created by impermanence but never populated
    fileSystems."/" = {
      device = "/dev/disk/by-uuid/61624efa-38b7-446f-8002-58da5c090c40";
      fsType = "btrfs";
      options = [ "subvolid=5" "compress=zstd" "noatime" ];  # Using btrfs root where actual data lives
    };

    # No separate /nix mount needed - it's in the root filesystem
    # The @nix subvolume exists but /nix data is actually in subvolid=5

    fileSystems."/home" = {
      device = "/dev/disk/by-uuid/61624efa-38b7-446f-8002-58da5c090c40";
      fsType = "btrfs";
      options = [ "subvol=@home" "compress=zstd" "noatime" ];
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/21FE-D958";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

    swapDevices = [ ];

    # Network configuration
    networking.useDHCP = lib.mkDefault true;

    # Platform configuration
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

    # Enable firmware (required for WiFi and other hardware)
    hardware.enableRedistributableFirmware = true;
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    hardware.ledger.enable = true;
  };
}