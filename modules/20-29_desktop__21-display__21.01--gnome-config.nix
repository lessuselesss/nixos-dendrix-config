# 21.01 GNOME Desktop Configuration (Flake-Parts Module)
# GNOME desktop environment with GDM
{ inputs, ... }:

{
  # Contribute GNOME configuration as a nixosModule
  flake.nixosModules."21.01-gnome-config" = { config, lib, pkgs, ... }: {
    # Enable the GNOME Desktop Environment
    services.xserver.enable = true;
    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;
    
    # Configure keymap
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };
    
    # Enable touchpad support (enabled by default in most desktop managers)
    services.libinput.enable = true;
    
    # Exclude some default GNOME applications
    environment.gnome.excludePackages = with pkgs; [
      gnome-photos
      gnome-tour
      cheese # webcam tool
      gnome-music
      epiphany # web browser
      geary # email reader
      gnome-characters
      totem # video player
      tali # poker game
      iagno # go game
      hitori # sudoku game
      atomix # puzzle game
    ];

    # Workaround for GNOME autologin
    # https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
    systemd.services."getty@tty1".enable = false;
    systemd.services."autovt@tty1".enable = false;

    # Container support for Waydroid and other containerized applications
    virtualisation.waydroid.enable = true;
    virtualisation.containers.enable = true;
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };
}