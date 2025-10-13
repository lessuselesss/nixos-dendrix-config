# 51.01 User Applications
# Desktop applications and utilities
{ inputs, ... }:

{
  flake.nixosModules.applications = { config, lib, pkgs, ... }: {
    home-manager.users.lessuseless = { pkgs, ... }: {
      home.packages = with pkgs; [
        # Web browsers
        google-chrome
        librewolf
        
        # Communication
        telegram-desktop
        beeper
        signal-desktop
        
        # Media and productivity
        obs-studio      # Streaming and recording
        transmission_4  # BitTorrent client
        bazecor        # Keyboard configuration tool
        
        # System utilities
        appimage-run   # AppImage support
        cloudflare-warp # VPN client
      ];
    };
  };
}