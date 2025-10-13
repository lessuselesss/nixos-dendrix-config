# 12.01 Networking Configuration (Flake-Parts Module)
# Network interfaces and connectivity
{ inputs, ... }:

{
  # Contribute networking configuration as a nixosModule
  flake.nixosModules.networking = { config, lib, pkgs, ... }: {
    networking.hostName = "nixos";
    networking.networkmanager.enable = true;

    # Extra hosts (commented out for now)
    networking.extraHosts = ''
      # Uncomment to block specific sites
      # 127.0.0.1 pinalove.com
      # 127.0.0.1 www.pinalove.com
      # 127.0.0.1 m.pinalove.com
      # 127.0.0.1 mobile.pinalove.com
    '';

    # Timezone
    time.timeZone = "America/Bahia_Banderas";

    # Disable network time synchronization (using default)
    services.timesyncd.enable = false;

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