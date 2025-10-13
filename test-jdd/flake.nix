# Working test of JDD modules in a traditional flake
{
  description = "Test JDD modules";
  
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; 
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };
  
  outputs = { self, nixpkgs, home-manager }: {
    nixosConfigurations.jdd-test = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inputs = self.inputs; };
      modules = [
        # Test core system modules
        ./modules/01.01_hardware.nix
        ./modules/01.02_boot.nix
        ./modules/01.04_networking.nix
        ./modules/01.05_system.nix
        ./modules/02.01_gnome.nix
        ./modules/02.03_audio.nix
        ./modules/07.01_users.nix
        ./modules/08.01_vpn.nix
        
        # Add home-manager
        home-manager.nixosModules.home-manager
        ./modules/07.02_home-manager.nix
        
        # Basic system config
        {
          system.stateVersion = "25.05";
          nixpkgs.config.allowUnfree = true;
        }
      ];
    };
  };
}