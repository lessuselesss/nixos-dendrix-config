# 82.01 Automated Home Backup on System Activation
# Backs up /home to external disk when NixOS is rebuilt/activated
{ inputs, ... }:

{
  flake.nixosModules."82.01-automated-home-backup" = { config, lib, pkgs, ... }:
    let
      cfg = config.services.automated-home-backup;

      # Backup script that checks for available disks and performs backup
      backupScript = pkgs.writeShellScript "automated-home-backup" ''
        set -e

        # Color codes for output
        RED='\033[0;31m'
        YELLOW='\033[1;33m'
        GREEN='\033[0;32m'
        NC='\033[0m' # No Color

        echo -e "''${GREEN}[Automated Home Backup]''${NC} Checking for backup disks..."

        # Check if any disk IDs are configured
        DISK_IDS=(${lib.concatStringsSep " " (map (id: ''"${id}"'') cfg.backupDiskIds)})

        if [ ''${#DISK_IDS[@]} -eq 0 ]; then
          echo -e "''${YELLOW}[WARNING]''${NC} No backup disk IDs configured!"
          echo "  Set 'services.automated-home-backup.backupDiskIds' to enable automatic backups."
          echo "  Example disk identifiers:"
          echo "    - UUID: 'ata-Samsung_SSD_860_EVO_500GB_S3Z9NB0K123456'"
          echo "    - By-ID: 'usb-Kingston_DataTraveler_3.0_ABC123-0:0'"
          echo ""
          echo "  Find your disk IDs with: ls -l /dev/disk/by-id/"
          exit 0
        fi

        # Check which disks are available
        AVAILABLE_DISK=""
        AVAILABLE_ID=""

        for disk_id in "''${DISK_IDS[@]}"; do
          # Try /dev/disk/by-id first
          if [ -e "/dev/disk/by-id/$disk_id" ]; then
            AVAILABLE_DISK="/dev/disk/by-id/$disk_id"
            AVAILABLE_ID="$disk_id"
            break
          fi

          # Try /dev/disk/by-uuid
          if [ -e "/dev/disk/by-uuid/$disk_id" ]; then
            AVAILABLE_DISK="/dev/disk/by-uuid/$disk_id"
            AVAILABLE_ID="$disk_id"
            break
          fi

          # Try as direct device path
          if [ -e "$disk_id" ]; then
            AVAILABLE_DISK="$disk_id"
            AVAILABLE_ID="$disk_id"
            break
          fi
        done

        if [ -z "$AVAILABLE_DISK" ]; then
          echo -e "''${YELLOW}[WARNING]''${NC} No configured backup disks are currently connected!"
          echo "  Configured disk IDs:"
          for disk_id in "''${DISK_IDS[@]}"; do
            echo "    - $disk_id"
          done
          echo ""
          echo "  Connect one of these disks to enable automatic backups."
          echo "  Or add another disk ID with:"
          echo "    services.automated-home-backup.backupDiskIds = [ \"your-disk-id\" ];"
          exit 0
        fi

        echo -e "''${GREEN}[OK]''${NC} Found backup disk: $AVAILABLE_ID"

        # Get the mountpoint for this disk
        MOUNT_POINT=$(findmnt -n -o TARGET --source "$AVAILABLE_DISK" 2>/dev/null || echo "")

        if [ -z "$MOUNT_POINT" ]; then
          echo -e "''${YELLOW}[WARNING]''${NC} Backup disk is not mounted!"
          echo "  Disk: $AVAILABLE_DISK"
          echo "  Please mount the disk before rebuilding to enable automatic backups."
          exit 0
        fi

        echo -e "''${GREEN}[OK]''${NC} Disk mounted at: $MOUNT_POINT"

        # Create backup directory with timestamp
        BACKUP_BASE="$MOUNT_POINT/${cfg.backupPath}"
        BACKUP_DIR="$BACKUP_BASE/home-backup-$(date +%Y%m%d-%H%M%S)"

        mkdir -p "$BACKUP_BASE"

        echo -e "''${GREEN}[Backup Started]''${NC} Backing up /home to $BACKUP_DIR"
        echo "  Source size: $(du -sh /home 2>/dev/null | cut -f1)"
        echo ""

        # Perform backup with rsync
        ${pkgs.rsync}/bin/rsync -aAX \
          --info=progress2 \
          ${lib.concatMapStringsSep " " (pattern: "--exclude='${pattern}'") cfg.excludePatterns} \
          /home/ \
          "$BACKUP_DIR/" || {
            echo -e "''${RED}[ERROR]''${NC} Backup failed!"
            exit 1
          }

        # Create backup manifest
        cat > "$BACKUP_DIR/BACKUP_INFO.txt" << EOF
        Backup Created: $(date)
        Hostname: $(${pkgs.hostname}/bin/hostname)
        Source: /home
        Destination: $BACKUP_DIR
        Disk ID: $AVAILABLE_ID
        Files: $(find "$BACKUP_DIR" -type f 2>/dev/null | wc -l)
        Directories: $(find "$BACKUP_DIR" -type d 2>/dev/null | wc -l)

        To restore:
          rsync -aAXv $BACKUP_DIR/ /home/
        EOF

        echo -e "''${GREEN}[Backup Complete]''${NC} Backup saved to: $BACKUP_DIR"
        echo "  Backup size: $(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)"
        echo ""

        # Clean up old backups if configured
        ${lib.optionalString (cfg.keepBackups != null) ''
          echo "Cleaning up old backups (keeping last ${toString cfg.keepBackups})..."
          cd "$BACKUP_BASE"
          ls -dt home-backup-* 2>/dev/null | tail -n +$((${toString cfg.keepBackups} + 1)) | xargs -r rm -rf
        ''}
      '';
    in
    {
      options.services.automated-home-backup = {
        enable = lib.mkEnableOption "automated home directory backup on system activation";

        backupDiskIds = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          example = [
            "ata-Samsung_SSD_860_EVO_500GB_S3Z9NB0K123456"
            "usb-Kingston_DataTraveler_3.0_ABC123-0:0"
            "1234-5678"  # UUID example
          ];
          description = ''
            List of disk identifiers to use for backups.
            Can be:
            - Disk IDs from /dev/disk/by-id/
            - UUIDs from /dev/disk/by-uuid/
            - Direct device paths like /dev/sdb1

            The first available disk will be used.
            If empty, a warning will be shown on system activation.

            Find disk IDs with: ls -l /dev/disk/by-id/
          '';
        };

        backupPath = lib.mkOption {
          type = lib.types.str;
          default = "nixos-backups";
          description = ''
            Path on the backup disk where backups will be stored.
            Relative to the mount point of the backup disk.
          '';
        };

        excludePatterns = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            ".cache"
            ".local/share/Trash"
            "*/node_modules"
            "*/.venv"
            "*/__pycache__"
          ];
          description = ''
            List of patterns to exclude from backups.
            Passed directly to rsync's --exclude option.
          '';
        };

        keepBackups = lib.mkOption {
          type = lib.types.nullOr lib.types.int;
          default = 5;
          description = ''
            Number of backup generations to keep.
            Older backups will be automatically deleted.
            Set to null to keep all backups.
          '';
        };

        runOnActivation = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Whether to run backup during system activation (nixos-rebuild switch).
            Disable this if you want to trigger backups manually.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        # Run backup on system activation
        system.activationScripts.automated-home-backup = lib.mkIf cfg.runOnActivation {
          text = ''
            # Run backup script
            ${backupScript} || true  # Don't fail activation if backup fails
          '';
          deps = [];  # Run early in activation
        };

        # Also provide as a standalone command
        environment.systemPackages = [
          (pkgs.writeShellScriptBin "backup-home-now" ''
            exec ${backupScript}
          '')
        ];
      };
    };
}
