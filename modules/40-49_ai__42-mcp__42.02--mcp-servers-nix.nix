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
  flake.nixosModules."42.02-mcp-overlay" = { pkgs, ... }: {
    nixpkgs.overlays = [
      inputs.mcp-servers.overlays.default
    ];
  };

  # Contribute MCP packages via home-manager as a nixosModule
  flake.nixosModules."42.02-mcp-packages" = { pkgs, ... }: {
    home-manager.users.lessuseless = { pkgs, ... }: {
      home.packages = with pkgs; [
        # File system and development tools - ONLY ONE AT A TIME DUE TO README.md CONFLICTS
        mcp-server-filesystem
        # mcp-server-git       # Conflicts with filesystem README.md
        # mcp-server-fetch     # Conflicts with filesystem README.md
        # mcp-server-memory    # Conflicts with filesystem README.md
        # mcp-server-time      # Conflicts with filesystem README.md
        # mcp-server-everything # Conflicts with filesystem README.md
        # mcp-server-sequential-thinking # Conflicts with filesystem README.md

        # Service integrations - These might work if they don't conflict
        context7-mcp
        github-mcp-server

        # Automation and testing
        playwright-mcp
        mcp-grafana
        serena
      ];
    };
  };
}