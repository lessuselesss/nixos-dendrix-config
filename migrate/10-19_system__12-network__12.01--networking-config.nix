# 12.01 Networking Configuration (Flake-Parts Module)
# Network interfaces and connectivity
{ inputs, ... }:

{
  # Contribute networking configuration as a nixosModule
  flake.nixosModules.networking = { config, lib, pkgs, ... }: {
    networking.hostName = "nixos";
    networking.networkmanager.enable = true;
    
    # Enable network discovery and printing services
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
    
    # Firewall configuration
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };
  };
}