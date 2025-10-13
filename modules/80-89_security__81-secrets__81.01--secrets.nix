# 81.01 Secrets Management
# Secure handling of API keys and sensitive data using sops-nix
{ inputs, ... }:

{
  flake.nixosModules.secrets = { config, lib, pkgs, ... }: {
    imports = [
      inputs.sops-nix.nixosModules.sops
    ];

    # Secrets management is now handled at the home-manager level
    # This module ensures sops-nix is available system-wide

    # System packages for secret management
    environment.systemPackages = with pkgs; [
      sops
      age
    ];
  };
}