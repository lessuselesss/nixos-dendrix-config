# Traditional NixOS configuration that imports our JDD modules
# This tests if our Johnny Decimal modules work outside the dendrix framework

{ config, pkgs, ... }:

{
  imports = [
    # System Foundation (01.xx)
    ./modules/01.01_hardware.nix
    ./modules/01.02_boot.nix
    ./modules/01.04_networking.nix
    ./modules/01.05_system.nix
    
    # Desktop Environment (02.xx)
    ./modules/02.01_gnome.nix
    ./modules/02.03_audio.nix
    
    # User Configuration (07.xx)
    ./modules/07.01_users.nix
    
    # Services (08.xx)  
    ./modules/08.01_vpn.nix
    
    # Security (09.xx)
    ./modules/09.01_secrets.nix
  ];

  # System state version
  system.stateVersion = "25.05";
}