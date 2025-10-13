# 03.01 Rust Development Environment
# Rust language toolchain and related tools
{ inputs, ... }:

{
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
}