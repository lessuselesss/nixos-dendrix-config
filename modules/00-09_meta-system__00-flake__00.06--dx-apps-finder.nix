# 00.06 DX-Apps Finder
# Hierarchical fuzzy finder for discovering and running dendrix apps
# Usage:
#   dx-apps                              # Interactive fuzzy finder
#   dx-apps -- [args]                    # Interactive with args passed to selected app
#   dx-apps run #XX.YY -- app-name [args] # Direct run mode
{ inputs, ... }:

{
  perSystem = { config, pkgs, system, ... }:
  let
    dxApps = pkgs.writeShellApplication {
      name = "dx-apps";

      runtimeInputs = with pkgs; [
        fzf
        jq
        gnugrep
        gawk
        coreutils
      ];

      text = ''
        #!/usr/bin/env bash
        set -euo pipefail

        # Colors
        GREEN='\033[0;32m'
        NC='\033[0m'

        # Check if we're in a flake directory
        if [ ! -f "flake.nix" ]; then
          echo "Error: Must run from a flake directory (no flake.nix found)"
          exit 1
        fi

        # Function to get all packages from flake
        get_packages() {
          nix eval .#packages.x86_64-linux --apply 'pkgs: builtins.attrNames pkgs' --json 2>/dev/null | jq -r '.[]'
        }

        # Function to format list for fzf
        format_for_fzf() {
          local packages
          packages=$(get_packages)

          # Filter to module-numbered packages and sort
          local module_packages
          module_packages=$(echo "$packages" | grep -E '^[0-9]{2}\.[0-9]{2}-' | sort)

          # Build hierarchical display
          local current_module=""

          echo "$module_packages" | while read -r pkg; do
            # Extract module number (XX.YY)
            local module_num
            module_num=$(echo "$pkg" | grep -oE '^[0-9]{2}\.[0-9]{2}')

            # If new module, print as header
            if [ "$module_num" != "$current_module" ]; then
              echo "$pkg"
              current_module="$module_num"
            fi

            # Print the app indented
            echo "    > $pkg"
          done
        }

        # Function to run an app
        run_app() {
          local app_name="$1"
          shift

          echo -e "''${GREEN}Running:''${NC} nix run .#$app_name -- $*" >&2
          exec nix run ".#$app_name" -- "$@"
        }

        # Function for direct run mode
        direct_run_mode() {
          shift # remove 'run' argument

          if [ $# -lt 1 ]; then
            echo "Usage: dx-apps run #XX.YY -- app-name [args]"
            exit 1
          fi

          # Parse #XX.YY
          MODULE_SPEC="$1"
          shift

          if [[ ! "$MODULE_SPEC" =~ ^#[0-9]{2}\.[0-9]{2}$ ]]; then
            echo "Error: Module spec must be in format #XX.YY (e.g., #00.05)"
            exit 1
          fi

          # Expect '--' separator
          if [ "$1" != "--" ]; then
            echo "Error: Expected '--' after module number"
            echo "Usage: dx-apps run #XX.YY -- app-name [args]"
            exit 1
          fi
          shift

          # Get app name
          if [ $# -lt 1 ]; then
            echo "Error: No app name provided"
            exit 1
          fi

          APP_NAME="$1"
          shift

          # Run the app
          run_app "$APP_NAME" "$@"
        }

        # Function for interactive mode with args
        interactive_with_args() {
          shift # remove '--' argument

          # Build and display list
          SELECTION=$(format_for_fzf | fzf \
            --ansi \
            --prompt="Select dendrix app (Enter or 'r' to run): " \
            --header="Apps grouped by module | Args will be passed: $*" \
            --bind="r:accept" \
            --preview='echo "Selected: {}"' \
            --preview-window=up:3:wrap)

          if [ -z "$SELECTION" ]; then
            echo "No selection made" >&2
            exit 1
          fi

          # Extract app name (remove arrow prefix if present)
          # shellcheck disable=SC2001
          APP_NAME=$(echo "$SELECTION" | sed 's/^[[:space:]]*> //')

          # Skip if it's a module header (no change after sed)
          if [[ "$APP_NAME" == "$SELECTION" ]] && [[ ! "$APP_NAME" =~ ^[[:space:]] ]]; then
            echo "Cannot run module header, select an app" >&2
            exit 1
          fi

          run_app "$APP_NAME" "$@"
        }

        # Function for basic interactive mode
        interactive_mode() {
          # Build and display list
          SELECTION=$(format_for_fzf | fzf \
            --ansi \
            --prompt="Select dendrix app (Enter or 'r' to run): " \
            --header="Apps grouped by module" \
            --bind="r:accept" \
            --preview='echo "Selected: {}"' \
            --preview-window=up:3:wrap)

          if [ -z "$SELECTION" ]; then
            echo "No selection made" >&2
            exit 1
          fi

          # Extract app name (remove arrow prefix if present)
          # shellcheck disable=SC2001
          APP_NAME=$(echo "$SELECTION" | sed 's/^[[:space:]]*> //')

          # Skip if it's a module header (no change after sed)
          if [[ "$APP_NAME" == "$SELECTION" ]] && [[ ! "$APP_NAME" =~ ^[[:space:]] ]]; then
            echo "Cannot run module header, select an app" >&2
            exit 1
          fi

          run_app "$APP_NAME"
        }

        # Main entry point
        case "''${1:-interactive}" in
          run)
            direct_run_mode "$@"
            ;;
          --)
            interactive_with_args "$@"
            ;;
          *)
            interactive_mode
            ;;
        esac
      '';
    };
  in
  {
    packages = {
      # Module attribute name (primary)
      "00.06-dx-apps" = dxApps;
      # Friendly alias
      dx-apps = dxApps;
    };

    apps = {
      # Module attribute name (primary)
      "00.06-dx-apps" = {
        type = "app";
        program = "${dxApps}/bin/dx-apps";
      };
      # Friendly alias
      dx-apps = {
        type = "app";
        program = "${dxApps}/bin/dx-apps";
      };
    };
  };

  # Also export as overlay for system packages
  flake.overlays."00.06-dx-apps" = final: prev: {
    dx-apps = inputs.self.packages.${prev.system}.dx-apps or prev.hello;
  };

  # Optional: Add to NixOS system packages
  flake.nixosModules."00.06-dx-apps" = { pkgs, ... }: {
    nixpkgs.overlays = [ inputs.self.overlays."00.06-dx-apps" ];
    environment.systemPackages = [ pkgs.dx-apps ];
  };
}
