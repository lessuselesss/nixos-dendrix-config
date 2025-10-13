# 21.01 GNOME Desktop Configuration (Flake-Parts Module)
# GNOME desktop environment with GDM
{ inputs, ... }:

{
  # Contribute GNOME configuration as a nixosModule
  flake.nixosModules.gnome = { config, lib, pkgs, ... }: {
    # Enable the GNOME Desktop Environment
    services.xserver.enable = true;
    services.xserver.displayManager.gdm.enable = true;
    services.xserver.desktopManager.gnome.enable = true;
    
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
  };
}