# 13.01 System Core Configuration (Hierarchical JDD)
# Main system configuration using hierarchical Johnny Decimal naming
{ inputs, ... }:

{
  flake.nixosConfigurations.nixos-hierarchical = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inputs = inputs; };
    modules = [
      # System Foundation (10-19)
      ./10-19_system@11-hardware-boot@11.01--hardware.nix
      ./10-19_system@11-hardware-boot@11.02--boot.nix
      ./10-19_system@12-network@12.01--networking.nix
      ./10-19_system@13-core@13.03--system-packages.nix
      
      # Desktop Environment (20-29) 
      ./20-29_desktop@21-display@21.01--gnome.nix
      ./20-29_desktop@22-audio@22.01--audio.nix
      
      # Development (30-39)
      ./30-39_development@31-systems-langs@31.01--rust.nix
      ./30-39_development@31-systems-langs@31.02--go.nix
      ./30-39_development@32-app-langs@32.01--python.nix
      ./30-39_development@32-app-langs@32.02--nodejs.nix
      ./30-39_development@33-specialized@33.01--blockchain.nix
      ./30-39_development@34-dev-tools@34.01--version-control.nix
      ./30-39_development@34-dev-tools@34.02--editors.nix
      ./30-39_development@34-dev-tools@34.03--terminals.nix
      
      # AI & Automation (40-49)
      ./40-49_ai@41-platforms@41.01--ollama.nix
      ./40-49_ai@41-platforms@41.02--claude-desktop.nix
      ./40-49_ai@42-mcp@42.01--mcp-servers.nix
      
      # Applications (50-59)
      ./50-59_apps@51-user-apps@51.01--applications.nix
      ./50-59_apps@52-containers@52.01--distrobox.nix
      
      # Users (60-69)
      ./60-69_users@61-system-users@61.01--users.nix
      ./60-69_users@62-home@62.01--home-manager.nix
      
      # Services (70-79)
      ./70-79_services@71-network-services@71.01--vpn.nix
      
      # Security (80-89)
      ./80-89_security@81-secrets@81.01--secrets.nix
      
      # Basic system config
      {
        system.stateVersion = "25.05";
        nixpkgs.config.allowUnfree = true;
      }
    ];
  };
}