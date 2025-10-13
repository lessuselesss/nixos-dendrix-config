# 32.01 Python Development Environment
# Python 3.13 and package management tools
{ inputs, ... }:

{
  flake.nixosModules.python = { config, lib, pkgs, ... }: {
    home-manager.users.lessuseless = { pkgs, ... }: {
      home.packages = with pkgs; [
        # Python language and tools
        python313
        python313Packages.pip
        pipx
        uv  # Fast Python package installer and resolver
      ];
    };
  };
}