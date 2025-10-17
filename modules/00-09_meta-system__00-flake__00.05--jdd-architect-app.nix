# 00.05 JDD Architect App
# Automated module renamer, index updater, and JDD validator
# Usage: nix run .#jdd-architect -- [command] [options]
{ inputs, ... }:

{
  perSystem = { config, pkgs, system, ... }:
  let
    jddArchitect = pkgs.writeShellApplication {
      name = "jdd-architect";

      runtimeInputs = with pkgs; [
        bash
        coreutils
        findutils
        gnugrep
        gnused
      ];

      text = ''
        # Get the project root (current directory)
        PROJECT_ROOT="$(pwd)"

        # If we're running from the flake, use the actual modules dir
        if [ -d "$PROJECT_ROOT/modules" ]; then
          export MODULES_DIR="$PROJECT_ROOT/modules"
        else
          echo "Error: Must run from project root (no modules/ directory found)"
          exit 1
        fi

        # Execute the actual jdd-architect script
        exec ${pkgs.bash}/bin/bash "${inputs.self}/scripts/jdd-architect.sh" "$@"
      '';
    };
  in
  {
    packages = {
      # Module attribute name (primary)
      "00.05-jdd-architect" = jddArchitect;
      # Friendly alias
      jdd-architect = jddArchitect;
    };

    apps = {
      # Module attribute name (primary)
      "00.05-jdd-architect" = {
        type = "app";
        program = "${jddArchitect}/bin/jdd-architect";
      };
      # Friendly alias
      jdd-architect = {
        type = "app";
        program = "${jddArchitect}/bin/jdd-architect";
      };
    };
  };

  # Also export as overlay for system packages
  flake.overlays."00.05-jdd-architect" = final: prev: {
    jdd-architect = inputs.self.packages.${prev.system}.jdd-architect or prev.hello;
  };

  # Optional: Add to NixOS system packages
  flake.nixosModules."00.05-jdd-architect" = { pkgs, ... }: {
    nixpkgs.overlays = [ inputs.self.overlays."00.05-jdd-architect" ];
    environment.systemPackages = [ pkgs.jdd-architect ];
  };
}
