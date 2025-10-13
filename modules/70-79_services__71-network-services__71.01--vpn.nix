# 71.01 VPN Services
# Cloudflare WARP VPN configuration
{ inputs, ... }:

{
  flake.nixosModules.vpn = { config, lib, pkgs, ... }: {
    # Enable Cloudflare WARP
    services.cloudflare-warp.enable = true;
  };
}