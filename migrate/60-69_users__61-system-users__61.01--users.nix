# 61.01 User Configuration
# System user accounts and permissions
{ inputs, ... }:

{
  flake.nixosModules.users = { config, lib, pkgs, ... }: {
    users.users.lessuseless = {
      isNormalUser = true;
      description = "Ashley Barr";
      extraGroups = [ "networkmanager" "wheel" "docker" ];
      
      # Required for rootless containers (Distrobox, rootless Docker)
      subGidRanges = [ { count = 65536; startGid = 100000; } ];
      subUidRanges = [ { count = 65536; startUid = 100000; } ];
      
      packages = with pkgs; [
        # User packages will be managed by Home Manager
      ];
    };

    # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
    systemd.services."getty@tty1".enable = false;
    systemd.services."autovt@tty1".enable = false;
  };
}