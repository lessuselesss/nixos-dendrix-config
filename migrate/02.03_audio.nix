# 02.03 Audio Configuration
# PipeWire audio system setup
{ config, lib, pkgs, ... }:

{
  # Disable PulseAudio in favor of PipeWire
  services.pulseaudio.enable = false;
  
  # Enable realtime kit for audio performance
  security.rtkit.enable = true;
  
  # PipeWire configuration
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # jack.enable = true;  # Uncomment for JACK support
  };
}