# 00.02 Nix App Dispatcher (Trampoline Pattern)
# Single entry point that dispatches to multiple "apps"
# Usage: nix run .#app -- <command> [args]
{ inputs, ... }:

{
  flake.overlays."00.02-app-dispatcher" = final: prev: {
    # Main dispatcher package
    nixapp = final.writeShellScriptBin "nixapp" ''
      #!/usr/bin/env bash
      set -euo pipefail

      COMMAND="''${1:-help}"
      shift || true

      case "$COMMAND" in
        map-impermanence|map|check)
          ${final.map-impermanence}/bin/map-impermanence "$@"
          ;;

        list|ls)
          echo "Available commands:"
          echo "  map-impermanence, map, check - Check btrfs/impermanence config"
          echo "  list, ls                      - Show this help"
          echo ""
          echo "Usage: nixapp <command> [args]"
          echo "   or: nix run .#nixapp -- <command> [args]"
          ;;

        help|--help|-h)
          echo "NixApp Dispatcher - Run utilities from this flake"
          echo ""
          echo "Usage: nixapp <command> [args]"
          echo ""
          echo "Commands:"
          echo "  map-impermanence   Check btrfs and impermanence configuration"
          echo "  list              Show available commands"
          echo "  help              Show this help"
          echo ""
          echo "Examples:"
          echo "  nixapp map-impermanence"
          echo "  nix run .#nixapp -- map"
          ;;

        *)
          echo "Unknown command: $COMMAND"
          echo "Run 'nixapp help' for available commands"
          exit 1
          ;;
      esac
    '';
  };

  # Export as a package for nix run
  flake.packages.x86_64-linux.default =
    let pkgs = import inputs.nixpkgs { system = "x86_64-linux"; };
        pkgs' = pkgs.extend inputs.self.overlays."00.02-app-dispatcher";
        pkgs'' = pkgs'.extend inputs.self.overlays."91.02-check-impermanence";
    in pkgs''.nixapp;

  # Also make it available under the name "nixapp"
  flake.packages.x86_64-linux.nixapp =
    inputs.self.packages.x86_64-linux.default;

  # Add to nixosModule
  flake.nixosModules."00.02-app-dispatcher" = { pkgs, ... }: {
    nixpkgs.overlays = [
      inputs.self.overlays."00.02-app-dispatcher"
    ];

    environment.systemPackages = [ pkgs.nixapp ];
  };
}
