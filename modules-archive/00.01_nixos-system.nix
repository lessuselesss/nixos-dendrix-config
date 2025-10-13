# 00.01 NixOS System Configuration
# Main system configuration that imports all Johnny Decimal modules
{ inputs, ... }:

{
  flake.nixosConfigurations.nixos = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    
    specialArgs = { inherit inputs; };
    
    modules = [
      # System Foundation (01.xx)
      ./01.01_hardware.nix
      ./01.02_boot.nix
      ./01.04_networking.nix
      ./01.05_system.nix
      
      # Desktop Environment (02.xx)
      ./02.01_gnome.nix
      ./02.03_audio.nix
      
      # Development Languages (03.xx)
      ./03.01_rust.nix
      ./03.02_go.nix
      ./03.03_python.nix
      ./03.04_nodejs.nix
      ./03.05_blockchain.nix
      
      # Development Tools (04.xx)
      ./04.01_version-control.nix
      ./04.02_editors.nix
      ./04.03_terminals.nix
      
      # AI & MCP Ecosystem (05.xx)
      ./05.01_ollama.nix
      ./05.02_claude-desktop.nix
      ./05.03_mcp-servers.nix
      
      # Applications & Containers (06.xx)
      ./06.01_applications.nix
      ./06.02_distrobox.nix
      
      # User Configuration (07.xx)
      ./07.01_users.nix
      ./07.02_home-manager.nix
      
      # Services (08.xx)
      ./08.01_vpn.nix
      
      # Security (09.xx)
      ./09.01_secrets.nix
    ];
  };
}