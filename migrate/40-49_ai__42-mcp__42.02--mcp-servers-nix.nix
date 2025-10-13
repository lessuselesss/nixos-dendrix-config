# 42.02 MCP Servers Nix Integration (Dendrix Module)
# Integration with natsukium/mcp-servers-nix for additional MCP servers
{ inputs, ... }:

{
  # Configure the flake input
  flake.inputs.mcp-servers = {
    url = "github:natsukium/mcp-servers-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # Contribute MCP overlay as a nixosModule
  flake.nixosModules.mcp-overlay = { pkgs, ... }: {
    nixpkgs.overlays = [
      inputs.mcp-servers.overlays.default
    ];
  };

  # Make packages available per-system
  perSystem = { pkgs, system, ... }: {
    # Make mcp-servers packages available
    packages = {
      # Core MCP servers
      inherit (inputs.mcp-servers.packages.${system})
        mcp-server-filesystem
        mcp-server-git
        mcp-server-fetch
        mcp-server-memory
        mcp-server-time
        mcp-server-everything
        mcp-server-sequential-thinking
        context7-mcp
        github-mcp-server
        mcp-grafana
        notion-mcp-server
        playwright-mcp
        serena;
    };
  };

  # Contribute MCP packages via home-manager as a nixosModule
  flake.nixosModules.mcp-packages = { ... }: {
    home-manager.users.lessuseless = { pkgs, ... }: {
      home.packages = with pkgs; [
        # File system and development tools
        mcp-server-filesystem
        mcp-server-git
        mcp-server-fetch
        
        # Memory and time utilities
        mcp-server-memory
        mcp-server-time
        
        # Advanced tools
        mcp-server-everything
        mcp-server-sequential-thinking
        
        # Service integrations
        context7-mcp
        github-mcp-server
        notion-mcp-server
        
        # Automation and testing
        playwright-mcp
        mcp-grafana
        serena
      ];
    };
  };
}