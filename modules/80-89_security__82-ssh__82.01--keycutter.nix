# 82.01 Keycutter SSH Key Management
# Open-source SSH key management tool for FIDO keys and multi-account access
{ inputs, ... }:

{
  flake.nixosModules.keycutter = { config, lib, pkgs, ... }:
    let
      # Build keycutter from source
      keycutter = pkgs.stdenv.mkDerivation {
        pname = "keycutter";
        version = "0.1.0-git";

        src = pkgs.fetchFromGitHub {
          owner = "lessuselesss";
          repo = "keycutter-flake";
          rev = "main";  # Or specific commit
          sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";  # Update on first build
        };

        buildInputs = with pkgs; [
          bash
          openssh
          gnupg
          # Add other dependencies as needed
        ];

        installPhase = ''
          mkdir -p $out/bin

          # Install keycutter scripts
          if [ -f keycutter ]; then
            cp keycutter $out/bin/
            chmod +x $out/bin/keycutter
          fi

          # Install any configuration templates
          if [ -d templates ]; then
            mkdir -p $out/share/keycutter
            cp -r templates $out/share/keycutter/
          fi

          # Install documentation if present
          if [ -f README.md ]; then
            mkdir -p $out/share/doc/keycutter
            cp README.md $out/share/doc/keycutter/
          fi
        '';

        meta = with pkgs.lib; {
          description = "SSH key management tool for FIDO keys and multi-account access";
          homepage = "https://github.com/lessuselesss/keycutter-flake";
          license = licenses.mit;  # Update if different
          platforms = platforms.unix;
        };
      };
    in
    {
      # Install keycutter
      environment.systemPackages = [
        keycutter
      ];

      # Home-manager configuration for per-user setup
      home-manager.users.lessuseless = { pkgs, ... }: {
        home.packages = [ keycutter ];

        # Create keycutter config directory
        home.file.".config/keycutter/.keep".text = "";

        # Session variables for keycutter
        home.sessionVariables = {
          KEYCUTTER_CONFIG_DIR = "${config.home.homeDirectory}/.config/keycutter";
        };

        # SSH configuration integration
        programs.ssh = {
          enable = true;

          # Keycutter-friendly SSH config
          extraConfig = ''
            # Keycutter managed keys
            # See ~/.config/keycutter/ for key configurations

            # Enable agent forwarding selectively (keycutter manages this)
            AddKeysToAgent yes

            # FIDO key support
            SecurityKeyProvider internal
          '';
        };

        # Helper script for keycutter setup
        home.file.".local/bin/keycutter-setup" = {
          executable = true;
          text = ''
            #!/usr/bin/env bash
            set -e

            echo "=== Keycutter SSH Key Management Setup ==="
            echo ""
            echo "Keycutter helps manage SSH keys for multiple accounts with FIDO support."
            echo ""
            echo "Features:"
            echo "  - FIDO SSH keys (YubiKey, etc.)"
            echo "  - Multi-account access (GitHub, GitLab, etc.)"
            echo "  - Selective SSH agent forwarding"
            echo "  - Public SSH key privacy"
            echo ""

            if [ ! -f ~/.config/keycutter/config.yaml ]; then
              echo "Creating default keycutter configuration..."
              mkdir -p ~/.config/keycutter

              cat > ~/.config/keycutter/config.yaml << 'EOF'
# Keycutter Configuration
# See: https://github.com/lessuselesss/keycutter-flake

accounts:
  # Example: Personal GitHub account
  # - name: personal-github
  #   service: github
  #   username: yourusername
  #   key_type: ed25519-sk  # FIDO key
  #   key_path: ~/.ssh/personal_github_fido

  # Example: Work GitLab account
  # - name: work-gitlab
  #   service: gitlab
  #   username: work-user
  #   key_type: ed25519
  #   key_path: ~/.ssh/work_gitlab

security:
  # Only present relevant keys to each host
  selective_forwarding: true

  # Require physical presence for FIDO keys
  require_presence: true

EOF
              echo "✅ Created ~/.config/keycutter/config.yaml"
              echo ""
              echo "Edit the config to add your accounts, then run:"
              echo "  keycutter generate-keys"
              echo ""
            else
              echo "✅ Keycutter already configured at ~/.config/keycutter/config.yaml"
              echo ""
            fi

            echo "Quick start:"
            echo "  1. Edit ~/.config/keycutter/config.yaml"
            echo "  2. Run: keycutter generate-keys"
            echo "  3. Run: keycutter sync-github  # Or your service"
            echo ""
            echo "For FIDO keys, make sure your YubiKey/security key is plugged in!"
          '';
        };
      };

      # Ensure SSH is enabled system-wide
      services.openssh.enable = lib.mkDefault false;  # Client only, not server

      # Enable FIDO/U2F support for security keys
      services.udev.packages = with pkgs; [
        yubikey-personalization
        libu2f-host
      ];

      # Add udev rules for FIDO devices
      services.udev.extraRules = ''
        # YubiKey
        SUBSYSTEM=="usb", ATTRS{idVendor}=="1050", GROUP="plugdev", MODE="0660"

        # Generic FIDO U2F devices
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", GROUP="plugdev", MODE="0660"
      '';
    };
}
