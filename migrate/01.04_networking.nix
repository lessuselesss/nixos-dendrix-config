# 01.04 Networking Configuration
# Network management and host configurations
{ config, lib, pkgs, ... }:

{
  networking = {
    hostName = "nixos";
    networkManager.enable = true;
    
    # Block unwanted domains
    extraHosts = ''
      127.0.0.1 pinalove.com
      127.0.0.1 www.pinalove.com
      127.0.0.1 m.pinalove.com
      127.0.0.1 mobile.pinalove.com
    '';
    
    # DHCP configuration
    useDHCP = lib.mkDefault true;
  };

  # Disable network time synchronization (using custom time service)
  services.timesyncd.enable = false;
}