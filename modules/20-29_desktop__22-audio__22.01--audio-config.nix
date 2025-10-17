# 22.01 Audio Configuration (Flake-Parts Module)
# PipeWire audio system configuration
{ inputs, ... }:

{
  # Contribute audio configuration as a nixosModule
  flake.nixosModules.audio = { config, lib, pkgs, ... }: {
    # Enable sound with PipeWire
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      
      # Uncomment for JACK applications
      # jack.enable = true;
    };
    
    # Additional audio packages
    environment.systemPackages = with pkgs; [
      pavucontrol  # PulseAudio Volume Control
      pulseaudio   # PulseAudio tools
    ];
  };
}