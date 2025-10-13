# 00.02 Minimal Test Configuration
# Minimal system for testing the Johnny Decimal structure
{ inputs, ... }:

{
  flake.nixosConfigurations.nixos-test = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    
    specialArgs = { inherit inputs; };
    
    modules = [
      # Import nixpkgs configuration
      ({ pkgs, ... }: {
        nixpkgs.config.allowUnfree = true;
      })
      
      # Just the essential system modules for testing
      ./01.01_hardware.nix
      ./01.02_boot.nix
      ./01.05_system.nix
    ];
  };
}