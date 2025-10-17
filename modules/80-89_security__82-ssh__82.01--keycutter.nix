# 82.01 Keycutter SSH Key Management
# Open-source SSH key management tool for FIDO keys and multi-account access
{ inputs, ... }:

{
  flake.nixosModules.keycutter = { config, lib, pkgs, ... }: {
    # Import keycutter's NixOS module from the flake
    imports = [
      inputs.keycutter.nixosModules.default
    ];

    # Enable keycutter
    programs.keycutter.enable = true;

    # Use the keycutter package from the flake
    programs.keycutter.package = inputs.keycutter.packages.${pkgs.system}.keycutter;

    # Home-manager configuration
    home-manager.users.lessuseless = { config, pkgs, ... }: {
      # Import keycutter's home-manager module
      imports = [
        inputs.keycutter.homeManagerModules.default
      ];

      # Enable keycutter for user
      programs.keycutter = {
        enable = true;
        package = inputs.keycutter.packages.${pkgs.system}.keycutter;
        configPath = "${config.home.homeDirectory}/.config/keycutter";
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
  };
}
