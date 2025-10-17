# 31.02 Go Development Environment
# Go programming language and tools
{ inputs, ... }:

{
  flake.nixosModules."31.02-go" = { config, lib, pkgs, ... }: {
    home-manager.users.lessuseless = { pkgs, ... }: {
      home.packages = with pkgs; [
        # Go language
        go
      ];
    };
  };
}