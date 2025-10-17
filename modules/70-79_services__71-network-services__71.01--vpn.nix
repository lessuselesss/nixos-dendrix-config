# 71.01 VPN Services
# Cloudflare WARP VPN configuration
{ inputs, ... }:

{
  flake.nixosModules."71.01-vpn" = { config, lib, pkgs, ... }: {
    # Enable Cloudflare WARP
    services.cloudflare-warp.enable = true;
  };
}