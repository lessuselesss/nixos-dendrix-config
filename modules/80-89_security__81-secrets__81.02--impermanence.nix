# 81.02 Impermanence Configuration
# System-level impermanence with ephemeral root on btrfs
{ inputs, ... }:

{
  flake.nixosModules."81.02-impermanence" = { config, lib, pkgs, ... }: {
    imports = [
      inputs.impermanence.nixosModules.impermanence
    ];

    # System-level persistent storage configuration
    environment.persistence."/persistent" = {
      hideMounts = true;

      directories = [
        # System directories that need to persist
        "/etc/nixos"              # NixOS configuration
        "/etc/ssh"                # SSH host keys
        "/etc/NetworkManager"     # Network connections
        "/var/log"                # System logs
        "/var/lib/nixos"          # NixOS state
        "/var/lib/systemd"        # Systemd state
        "/var/lib/bluetooth"      # Bluetooth pairings
        "/var/lib/containers"     # Podman/Docker containers
        "/var/lib/waydroid"       # Waydroid data
      ];

      files = [
        "/etc/machine-id"         # Machine ID
        "/etc/adjtime"            # Hardware clock adjustment
      ];

      users.lessuseless = {
        directories = [
          # User home directories to persist
          "recovered-dendrix-config"
          "recovered_avif_images"
          "go"
          ".npm"
          ".pki"
          ".nix-defexpr"

          # Application data
          ".local/share/keyrings"
          ".local/share/containers"
          ".local/share/waydroid"

          # Config directories
          ".config/distrobox"
          ".config/google-chrome"
          ".config/fontconfig"
          ".claude"
          ".claude-self-reflect"

          # SSH keys (critical!)
          ".ssh"

          # Development
          ".cache/uv"
          ".cache/nix"
        ];

        files = [
          ".bash_history"
          ".claude.json"
          "MIGRATION_SUMMARY.txt"
          "SECURITY_MIGRATION_COMPLETE.md"
        ];
      };
    };

    # Ensure persistent directory exists
    systemd.tmpfiles.rules = [
      "d /persistent 0755 root root -"
      "d /persistent/home 0755 root root -"
      "d /persistent/home/lessuseless 0700 lessuseless users -"
    ];

    # Boot configuration - clean root subvolume on boot (ephemeral)
    boot.initrd.postDeviceCommands = lib.mkAfter ''
      # Mount btrfs root to manage subvolumes
      mkdir -p /mnt
      mount -t btrfs -o subvol=/ /dev/disk/by-uuid/61624efa-38b7-446f-8002-58da5c090c40 /mnt

      # Clean root subvolume on boot (ephemeral)
      if [[ -e /mnt/@ ]]; then
          mkdir -p /mnt/@-old
          timestamp=$(date --date="@$(stat -c %Y /mnt/@)" "+%Y%m%d%H%M%S")
          mv /mnt/@ "/mnt/@-old-$timestamp"
          btrfs subvolume delete -C "/mnt/@-old-$timestamp"
      fi

      # Create fresh root subvolume
      btrfs subvolume create /mnt/@

      umount /mnt
    '';
  };
}
