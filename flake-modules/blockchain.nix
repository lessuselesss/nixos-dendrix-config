# 33.01 Blockchain Development
# Foundry framework and blockchain tools
{ inputs, ... }:
{
  flake.nixosModules.blockchain = { config, lib, pkgs, ... }: {
    home-manager.users.lessuseless = { pkgs, ... }: {
      home.packages = with pkgs; [
        # Blockchain development
        foundry  # Ethereum development toolkit
      ];
    };
  };
}