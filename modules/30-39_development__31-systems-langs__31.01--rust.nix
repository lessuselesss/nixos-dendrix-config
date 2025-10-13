# 31.01 Rust Development Environment
# Rust language toolchain and related tools
{ inputs, ... }:

{
  flake.nixosModules.rust = { config, lib, pkgs, ... }: {
    home-manager.users.lessuseless = { pkgs, ... }: {
      home.packages = with pkgs; [
        # Rust toolchain
        cargo
        
        # Build tools
        gcc
        pkg-config
        gnumake
      ];
    };
  };
}