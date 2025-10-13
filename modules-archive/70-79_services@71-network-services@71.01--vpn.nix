# 71.01 VPN Services
# Cloudflare WARP VPN configuration
{ config, lib, pkgs, ... }:

{
  # Enable Cloudflare WARP
  services.cloudflare-warp.enable = true;
}