# 00.03 Per-System Apps (Flake-Parts Compatible)
# Uses flake-parts perSystem properly
{ inputs, ... }:

{
  perSystem = { config, self', inputs', pkgs, system, ... }: {
    packages = {
      nixapp-test = pkgs.writeShellScriptBin "nixapp-test" ''
        echo "SUCCESS! This works with flake-parts perSystem!"
        echo "You can run: nix run .#nixapp-test"
      '';

      map-impermanence-fp = pkgs.writeShellScriptBin "map-impermanence" ''
        #!/usr/bin/env bash
        echo "Btrfs & Impermanence Health Check"
        mount | grep btrfs | head -5
      '';
    };
  };
}
