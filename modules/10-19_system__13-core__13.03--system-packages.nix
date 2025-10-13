# 13.03 Core System Configuration (Flake-Parts Module)
# System-wide settings and features
{ inputs, ... }:

{
  # Contribute system configuration as a nixosModule
  flake.nixosModules.system-packages = { config, lib, pkgs, ... }: {
    # Locale settings
    i18n.defaultLocale = "en_US.UTF-8";

    # Enable Nix flakes and experimental features
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    # Enable direnv
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # Enable appimage support
    programs.appimage = {
      enable = true;
      binfmt = true;
    };

    # Enable printing services
    services.printing.enable = true;

    # System packages
    programs.firefox.enable = true;
    programs.bazecor.enable = true;

    # Core system packages
    environment.systemPackages = with pkgs; [
      # Core utilities
      nix-direnv
      vim
      wget
      curl
      git

      # Container support
      distrobox

      # Development tools
      code-cursor
    ];

    # Font configuration
    fonts = {
      packages = with pkgs; [
        font-awesome
        roboto
        source-sans-pro
        source-sans
      ];
    };
  };
}