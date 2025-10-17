# 31.01 Rust Development Environment
# Rust language toolchain and related tools
{ inputs, ... }:

{
  flake.nixosModules."31.01-rust" = { config, lib, pkgs, ... }: {
    home-manager.users.lessuseless = { pkgs, ... }: {
      home.packages = with pkgs; [
        # Rust toolchain - using rustup instead of cargo to avoid conflicts
        # (rustup provides cargo, rustc, and other tools)
        # Note: 81.03-ledger-age-tools also uses rustup
        # cargo  # Commented out - conflicts with rustup

        # Build tools
        gcc
        pkg-config
        gnumake
      ];
    };
  };
}