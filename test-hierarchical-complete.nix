# Test complete hierarchical JDD system in traditional NixOS context
{
  description = "Test complete hierarchical JDD modules";
  
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; 
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };
  
  outputs = { self, nixpkgs, home-manager }: {
    nixosConfigurations.hierarchical-complete = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inputs = self.inputs; };
      modules = [
        # System Foundation (10-19)
        ./modules/10-19_system__11-hardware-boot__11.01--hardware-config.nix
        ./modules/10-19_system__11-hardware-boot__11.02--boot-config.nix
        ./modules/10-19_system__12-network__12.01--networking-config.nix
        ./modules/10-19_system__13-core__13.03--system-packages.nix
        
        # Desktop Environment (20-29) 
        ./modules/20-29_desktop__21-display__21.01--gnome-config.nix
        ./modules/20-29_desktop__22-audio__22.01--audio-config.nix
        
        # Development (30-39)
        ./modules/30-39_development__31-systems-langs__31.01--rust.nix
        ./modules/30-39_development__31-systems-langs__31.02--go.nix
        ./modules/30-39_development__32-app-langs__32.01--python.nix
        ./modules/30-39_development__32-app-langs__32.02--nodejs.nix
        ./modules/30-39_development__33-specialized__33.01--blockchain.nix
        ./modules/30-39_development__34-dev-tools__34.01--version-control.nix
        ./modules/30-39_development__34-dev-tools__34.02--editors.nix
        ./modules/30-39_development__34-dev-tools__34.03--terminals.nix
        
        # AI & Automation (40-49)
        ./modules/40-49_ai__41-platforms__41.01--ollama.nix
        ./modules/40-49_ai__41-platforms__41.02--claude-desktop.nix
        ./modules/40-49_ai__42-mcp__42.01--mcp-servers.nix
        
        # Applications (50-59)
        ./modules/50-59_apps__51-user-apps__51.01--applications.nix
        ./modules/50-59_apps__52-containers__52.01--distrobox.nix
        
        # Users (60-69)
        ./modules/60-69_users__61-system-users__61.01--users.nix
        ./modules/60-69_users__62-home__62.01--home-manager.nix
        
        # Services (70-79)
        ./modules/70-79_services__71-network-services__71.01--vpn.nix
        
        # Security (80-89)
        ./modules/80-89_security__81-secrets__81.01--secrets.nix
        
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