# 09.01 Module Structure Test
# Test module demonstrating correct flake-parts + import-tree patterns
{ inputs, ... }:

{
  # Test 1: NixOS Module Export
  flake.nixosModules."09.01-test-nixos-module" = { config, lib, pkgs, ... }: {
    # This demonstrates a properly structured NixOS module
    environment.systemPackages = [ ];  # Empty for testing
  };

  # Test 2: Overlay Export
  flake.overlays."09.01-test-overlay" = final: prev: {
    test-package = prev.hello;  # Simple test overlay
  };

  # Test 3: perSystem Package Export
  perSystem = { config, pkgs, system, ... }:
  let
    testPackage = pkgs.writeShellScriptBin "test-module-structure" ''
      #!/usr/bin/env bash
      echo "✅ Module structure test PASSED"
      echo "   - perSystem packages work correctly"
      echo "   - Flake-parts merging is functional"
      echo "   - import-tree integration successful"
    '';
  in
  {
    packages = {
      # Module attribute name (primary)
      "09.01-test-module-structure" = testPackage;
      # Friendly aliases
      test-package = testPackage;
      test-module-structure = testPackage;
    };

    # Test 4: perSystem App Export
    apps = {
      # Module attribute name (primary)
      "09.01-test-structure" = {
        type = "app";
        program = "${testPackage}/bin/test-module-structure";
      };
      # Friendly aliases
      test-structure = {
        type = "app";
        program = "${testPackage}/bin/test-module-structure";
      };
      test-package = {
        type = "app";
        program = "${testPackage}/bin/test-module-structure";
      };
    };
  };
}
