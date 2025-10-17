# 00.01 Hierarchical JDD System (Flake-Parts Module)
# Main system that imports all hierarchical Johnny Decimal modules
{ inputs, ... }:

{
  flake.nixosConfigurations.nixos = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      # Meta/AI Tools (00-09)
      inputs.self.nixosModules."04.02-llamafile-package"
      inputs.self.nixosModules."04.03-jdd-index"
      inputs.self.nixosModules."04.01-jdd-llamafile-assistant"

      # System Foundation (10-19)
      inputs.self.nixosModules."11.01-hardware-config"
      inputs.self.nixosModules."11.02-boot-config"
      inputs.self.nixosModules."12.01-networking-config"
      inputs.self.nixosModules."12.02-btrfs-validation"
      inputs.self.nixosModules."13.03-system-packages"

      # Desktop Environment (20-29)
      inputs.self.nixosModules."21.01-gnome-config"
      inputs.self.nixosModules."22.01-audio-config"
      # inputs.self.nixosModules."23.01-niri"  # DISABLED - Conflicts with GNOME/GDM

      # Development (30-39)
      inputs.self.nixosModules."31.01-rust"
      inputs.self.nixosModules."31.02-go"
      inputs.self.nixosModules."32.01-python"
      inputs.self.nixosModules."32.02-nodejs"
      inputs.self.nixosModules."33.01-blockchain"
      inputs.self.nixosModules."34.01-version-control"
      inputs.self.nixosModules."34.02-editors"
      inputs.self.nixosModules."34.03-terminals"

      # AI & Automation (40-49)
      inputs.self.nixosModules."41.01-ollama"
      inputs.self.nixosModules."41.02-claude-desktop"
      inputs.self.nixosModules."42.01-mcp-servers"
      inputs.self.nixosModules."42.02-mcp-overlay"
      inputs.self.nixosModules."42.02-mcp-packages"

      # Applications (50-59)
      inputs.self.nixosModules."51.01-applications"
      inputs.self.nixosModules."52.01-distrobox"

      # Users (60-69)
      inputs.self.nixosModules."61.01-users"
      inputs.self.nixosModules."62.01-home-manager"

      # Services (70-79)
      # inputs.self.nixosModules."71.01-vpn"  # DISABLED - May cause network issues

      # Security (80-89)
      inputs.self.nixosModules."81.01-secrets"
      # inputs.self.nixosModules."81.02-impermanence"  # DISABLED - Causes Stage 1 boot failure
      # inputs.self.nixosModules."81.03-ledger-age-tools"  # DISABLED - Testing
      # inputs.self.nixosModules."81.03-secrets-validation"  # DISABLED - Testing
      # inputs.self.nixosModules."82.01-keycutter"  # DISABLED - May cause auth issues
      # inputs.self.nixosModules."82.01-automated-home-backup"  # DISABLED - Runs on activation
      
      # Base system configuration
      {
        system.stateVersion = "25.05";
        nixpkgs.config.allowUnfree = true;
      }
    ];
  };
}