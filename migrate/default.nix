{ inputs, ... }:
{
  imports = [
    inputs.flake-file.flakeModules.dendritic
    ./00-19_meta__00-system__00.01--hierarchical-system.nix  # Hierarchical JDD system
    # ./00.02_minimal-test.nix  # Minimal test - disabled
  ];

  flake-file.description = "NixOS configuration with Johnny Decimal organization";
}
