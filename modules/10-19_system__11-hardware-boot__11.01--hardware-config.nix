# 11.01 Hardware Configuration (Flake-Parts Module)
# System hardware configuration for x86_64-linux platform
{ inputs, ... }:

{
  # Contribute to nixosConfigurations by providing a module
  flake.nixosModules.hardware = { config, lib, pkgs, ... }: {
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

    # File systems - Btrfs with compression and subvolumes
    fileSystems."/" = {
      device = "/dev/disk/by-uuid/61624efa-38b7-446f-8002-58da5c090c40";
      fsType = "btrfs";
      options = [ "subvol=@" "compress=zstd" "noatime" ];
    };

    fileSystems."/persistent" = {
      device = "/dev/disk/by-uuid/61624efa-38b7-446f-8002-58da5c090c40";
      fsType = "btrfs";
      options = [ "subvol=@persistent" "compress=zstd" "noatime" ];
      neededForBoot = true;
    };

    fileSystems."/nix" = {
      device = "/dev/disk/by-uuid/61624efa-38b7-446f-8002-58da5c090c40";
      fsType = "btrfs";
      options = [ "subvolid=5" "compress=zstd" "noatime" ];
    };

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
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    hardware.ledger.enable = true;
  };
}