# 00.01 Hierarchical JDD System (Flake-Parts Module)
# Main system that imports all hierarchical Johnny Decimal modules
{ inputs, ... }:

{
  flake.nixosConfigurations.nixos-hierarchical-fp = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      # Meta/AI Tools (00-09)
      inputs.self.nixosModules.llamafile-overlay
      inputs.self.nixosModules.jdd-index
      inputs.self.nixosModules.jdd-llamafile

      # System Foundation (10-19)
      inputs.self.nixosModules.hardware
      inputs.self.nixosModules.boot
      inputs.self.nixosModules.networking
      inputs.self.nixosModules.system-packages
      
      # Desktop Environment (20-29)
      inputs.self.nixosModules.gnome
      inputs.self.nixosModules.audio
      
      # Development (30-39)
      inputs.self.nixosModules.rust
      inputs.self.nixosModules.go
      inputs.self.nixosModules.python
      inputs.self.nixosModules.nodejs
      inputs.self.nixosModules.blockchain
      inputs.self.nixosModules.version-control
      inputs.self.nixosModules.editors
      inputs.self.nixosModules.terminals
      
      # AI & Automation (40-49)
      inputs.self.nixosModules.ollama
      inputs.self.nixosModules.claude-desktop
      inputs.self.nixosModules.mcp-servers
      inputs.self.nixosModules.mcp-overlay
      inputs.self.nixosModules.mcp-packages
      
      # Applications (50-59)
      inputs.self.nixosModules.applications
      inputs.self.nixosModules.distrobox
      
      # Users (60-69)
      inputs.self.nixosModules.users
      inputs.self.nixosModules.home-manager
      
      # Services (70-79)
      inputs.self.nixosModules.vpn

      # Security (80-89)
      inputs.self.nixosModules.secrets
      inputs.self.nixosModules.impermanence
      inputs.self.nixosModules.ledger-age
      
      # Base system configuration
      {
        system.stateVersion = "25.05";
        nixpkgs.config.allowUnfree = true;
      }
    ];
  };
}