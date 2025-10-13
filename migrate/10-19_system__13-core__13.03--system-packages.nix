# 13.03 Core System Configuration (Flake-Parts Module)
# System-wide settings and features
{ inputs, ... }:

{
  # Contribute system configuration as a nixosModule
  flake.nixosModules.system-packages = { config, lib, pkgs, ... }: {
    # Time zone configuration
    time.timeZone = "America/Bahia_Banderas";
    
    # Locale settings
    i18n.defaultLocale = "en_US.UTF-8";
    
    # Enable Nix flakes and experimental features
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    
    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;
    
    # Enable printing services
    services.printing.enable = true;
    
    # System packages
    programs.firefox.enable = true;
    programs.bazecor.enable = true;
  };
}