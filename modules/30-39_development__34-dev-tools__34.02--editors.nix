# 34.02 Development Editors
# Code editors and development tools
{ inputs, ... }:

{
  flake.nixosModules."34.02-editors" = { config, lib, pkgs, ... }: {
    home-manager.users.lessuseless = { pkgs, ... }: {
      home.packages = with pkgs; [
        # Editors
        zed-editor   # Modern code editor
        claude-code  # AI-powered coding assistant
        
        # Documentation and writing
        typst        # Modern markup-based typesetting system
        
        # Testing and automation
        playwright   # Web testing framework
      ];
    };
  };
}