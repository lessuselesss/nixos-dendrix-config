# 42.01 MCP Server Configuration
# Model Context Protocol server setup for AI tools
{ inputs, ... }:

{
  flake.nixosModules."42.01-mcp-servers" = { config, lib, pkgs, ... }: {
    home-manager.users.lessuseless = { pkgs, ... }: {
      # MCP server configuration file
      # WARNING: This contains placeholder API keys - implement proper secrets management!
      home.file.".config/ai/ehmpeecee.json".text = ''
        {
          "mcpServers": {
            "nixos": {
              "command": "nix",
              "args": ["run", "github:utensils/mcp-nixos", "--"]
            },
            "github": {
              "command": "npx",
              "args": ["-y", "@modelcontextprotocol/server-github"],
              "env": {
                "GITHUB_PERSONAL_ACCESS_TOKEN": "REDACTED_GITHUB_TOKEN"
              }
            },
            "github-cli": {
              "command": "npx",
              "args": ["-y", "@modelcontextprotocol/server-github-cli"]
            },
            "jujutsu": {
              "command": "npx",
              "args": ["-y", "@modelcontextprotocol/server-jujutsu"]
            },
            "taskmaster": {
              "command": "npx",
              "args": ["-y", "@seacows/taskmaster-mcp-tool"],
              "env": {
                "ANTHROPIC_API_KEY": "YOUR_ANTHROPIC_API_KEY_HERE",
                "PERPLEXITY_API_KEY": "YOUR_PERPLEXITY_API_KEY_HERE",
                "OPENAI_API_KEY": "YOUR_OPENAI_KEY_HERE",
                "GOOGLE_API_KEY": "REDACTED_GOOGLE_KEY",
                "MISTRAL_API_KEY": "YOUR_MISTRAL_KEY_HERE",
                "OPENROUTER_API_KEY": "REDACTED_OPENROUTER_KEY",
                "XAI_API_KEY": "YOUR_XAI_KEY_HERE",
                "AZURE_OPENAI_API_KEY": "YOUR_AZURE_KEY_HERE",
                "OLLAMA_API_KEY": "YOUR_OLLAMA_API_KEY_HERE"
              }
            }
          }
        }
      '';

      # TODO: Move to proper secrets management
      # TODO: Use sops.secrets for all API keys
      # TODO: Create systemd service for MCP servers if needed
    };
  };
}