# 81.01 Secrets Management
# Secure handling of API keys and sensitive data using sops-nix
{ inputs, ... }:

{
  flake.nixosModules."81.01-secrets" = { config, lib, pkgs, ... }: {
    imports = [
      inputs.sops-nix.nixosModules.sops
    ];

    # System-level secrets configuration
    sops = {
      defaultSopsFile = ./../../secrets.yaml;
      age.keyFile = "/home/lessuseless/.config/sops/age/keys.txt";

      # WiFi credentials for NetworkManager
      secrets = {
        wifi-ssid = {
          mode = "0440";
          owner = "root";
          group = "networkmanager";
        };
        wifi-password = {
          mode = "0440";
          owner = "root";
          group = "networkmanager";
        };
      };
    };

    # System packages for secret management
    environment.systemPackages = with pkgs; [
      sops
      age
    ];
  };
}