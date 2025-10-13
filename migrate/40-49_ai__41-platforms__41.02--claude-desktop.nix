# 41.02 Claude Desktop Application
# Claude Desktop with FHS environment for AI assistance
{ inputs, ... }:

{
  flake.nixosModules.claude-desktop = { config, lib, pkgs, ... }: {
    home-manager.users.lessuseless = { pkgs, ... }: {
      home.packages = with pkgs; [
        # TODO: Add Claude Desktop when input is available
        # inputs.claude-desktop.packages.${pkgs.system}.claude-desktop-with-fhs
        
        # Placeholder for now - depends on claude-desktop input in flake.nix
      ];
    };
  };
}