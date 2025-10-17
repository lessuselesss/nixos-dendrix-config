# 81.03 Ledger Age Tools
# Tools and environment for installing Age Identity app on Ledger devices
{ inputs, ... }:

{
  flake.nixosModules."81.03-ledger-age-tools" = { config, lib, pkgs, ... }: {
    home-manager.users.lessuseless = { pkgs, ... }: {
      home.packages = with pkgs; [
        # Development tools for Ledger apps
        python3
        pipx
        rustup  # Includes cargo, so don't add cargo separately
        # cargo  # Conflicts with rustup which already provides cargo
        gcc
        pkg-config
        libudev-zero
        hidapi
      ];

      # Create a helper script for installing the Age Identity app
      home.file.".local/bin/install-ledger-age-app".text = ''
        #!/usr/bin/env bash
        set -e

        echo "=== Ledger Age Identity App Installer ==="
        echo ""
        echo "This script will:"
        echo "1. Install cargo-ledger (Rust tool for building Ledger apps)"
        echo "2. Install ledgerctl (Python tool for loading apps)"
        echo "3. Clone and build the Age Identity app"
        echo "4. Load it onto your Ledger device"
        echo ""
        read -p "Continue? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi

        # Install cargo-ledger
        echo "Installing cargo-ledger..."
        cargo install cargo-ledger

        # Install ledgerctl via pipx
        echo "Installing ledgerctl..."
        pipx install ledgerctl

        # Clone the Age app repository
        APP_DIR="$HOME/.local/share/ledger-apps/app-age"
        if [ ! -d "$APP_DIR" ]; then
            echo "Cloning Age Identity app repository..."
            mkdir -p "$HOME/.local/share/ledger-apps"
            git clone https://github.com/Ledger-Donjon/app-age "$APP_DIR"
        else
            echo "Age app repository already exists at $APP_DIR"
        fi

        cd "$APP_DIR"

        # Detect Ledger device
        echo ""
        echo "Which Ledger device do you have?"
        echo "1) Nano S Plus"
        echo "2) Nano X"
        read -p "Enter choice (1 or 2): " device_choice

        case $device_choice in
            1)
                DEVICE="nanosplus"
                ;;
            2)
                DEVICE="nanox"
                ;;
            *)
                echo "Invalid choice"
                exit 1
                ;;
        esac

        echo ""
        echo "Building Age app for $DEVICE..."
        echo "Make sure your Ledger is connected and unlocked!"
        echo ""
        read -p "Press Enter when ready..."

        # Build and load the app
        cargo ledger build "$DEVICE" --load

        echo ""
        echo "=== Installation complete! ==="
        echo "The Age Identity app should now be installed on your Ledger device."
        echo ""
        echo "To use it:"
        echo "  1. Open the Age app on your Ledger"
        echo "  2. Use: age-plugin-ledger --generate"
        echo "  3. Follow the prompts to create an age identity"
      '';

      home.file.".local/bin/install-ledger-age-app".executable = true;
    };
  };
}
