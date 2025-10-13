# Test hierarchical JDD modules with Nix-compatible separators
{
  description = "Test hierarchical JDD modules";
  
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; 
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };
  
  outputs = { self, nixpkgs, home-manager }: {
    nixosConfigurations.hierarchical-test = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inputs = self.inputs; };
      modules = [
        # Test hierarchical modules with __ separator
        ../modules/10-19_system__11-hardware-boot__11.01--hardware.nix
        ../modules/10-19_system__11-hardware-boot__11.02--boot.nix
        
        # Add home-manager
        home-manager.nixosModules.home-manager
        
        # Basic system config
        {
          system.stateVersion = "25.05";
          nixpkgs.config.allowUnfree = true;
        }
      ];
    };
  };
}