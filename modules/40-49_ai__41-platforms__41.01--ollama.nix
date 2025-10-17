# 41.01 Ollama Local AI
# Local AI model serving with Ollama
{ inputs, ... }:

{
  flake.nixosModules."41.01-ollama" = { config, lib, pkgs, ... }: {
    home-manager.users.lessuseless = { pkgs, ... }: {
      home.packages = with pkgs; [
        # Local AI
        ollama      # Run large language models locally
        gemini-cli  # Gemini CLI tool for gemini-mcp-tool
      ];
    };
  };
}