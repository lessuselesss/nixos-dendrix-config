# 12.02 Btrfs Subvolume Validation
# Validates that required btrfs subvolumes exist before activation
{ inputs, ... }:

{
  flake.nixosModules."12.02-btrfs-validation" = { config, lib, pkgs, ... }:
  let
    # Extract btrfs filesystem configurations
    btrfsFilesystems = lib.filterAttrs
      (name: fs: fs.fsType or "" == "btrfs" && fs.device or "" != "")
      config.fileSystems;

    # Get unique btrfs devices
    btrfsDevices = lib.unique (lib.mapAttrsToList (name: fs: fs.device) btrfsFilesystems);

    # Extract subvolume names from mount options
    getSubvolFromOptions = options:
      let
        subvolOpts = lib.filter (opt: lib.hasPrefix "subvol=" opt) options;
      in
        if subvolOpts != []
        then lib.removePrefix "subvol=" (lib.head subvolOpts)
        else null;

    # Build list of expected subvolumes per device
    expectedSubvolumes = lib.listToAttrs (
      lib.concatMap (device:
        let
          deviceFilesystems = lib.filterAttrs (name: fs: fs.device == device) btrfsFilesystems;
          subvols = lib.filter (s: s != null) (
            lib.mapAttrsToList (name: fs:
              getSubvolFromOptions (fs.options or [])
            ) deviceFilesystems
          );
        in
          if subvols != [] then [{
            name = device;
            value = subvols;
          }] else []
      ) btrfsDevices
    );

    # Check script that validates subvolumes exist
    checkScript = pkgs.writeScriptBin "check-btrfs-subvolumes" ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      MISSING_SUBVOLUMES=()

      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (device: subvols: ''
        # Check ${device}
        if [ -b "${device}" ] || [ -e "${device}" ]; then
          TEMP_MOUNT=$(mktemp -d)
          if ${pkgs.util-linux}/bin/mount -t btrfs -o subvolid=5 "${device}" "$TEMP_MOUNT" 2>/dev/null; then
            ${lib.concatStringsSep "\n" (map (subvol: ''
              if [ ! -d "$TEMP_MOUNT/${subvol}" ]; then
                MISSING_SUBVOLUMES+=("${device}:${subvol}")
              fi
            '') subvols)}
            ${pkgs.util-linux}/bin/umount "$TEMP_MOUNT"
          fi
          rmdir "$TEMP_MOUNT"
        fi
      '') expectedSubvolumes)}

      if [ ''${#MISSING_SUBVOLUMES[@]} -gt 0 ]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "⚠️  BTRFS SUBVOLUME VALIDATION WARNING"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "The following btrfs subvolumes are configured but DO NOT EXIST:"
        echo ""

        # Group missing subvolumes by device
        declare -A DEVICE_SUBVOLS
        for missing in "''${MISSING_SUBVOLUMES[@]}"; do
          DEVICE="''${missing%%:*}"
          SUBVOL="''${missing##*:}"
          if [ -z "''${DEVICE_SUBVOLS[$DEVICE]:-}" ]; then
            DEVICE_SUBVOLS[$DEVICE]="$SUBVOL"
          else
            DEVICE_SUBVOLS[$DEVICE]="''${DEVICE_SUBVOLS[$DEVICE]} $SUBVOL"
          fi
        done

        # Display missing subvolumes grouped by device
        for device in "''${!DEVICE_SUBVOLS[@]}"; do
          echo "  Device: $device"
          for subvol in ''${DEVICE_SUBVOLS[$device]}; do
            echo "    • $subvol"
          done
          echo ""
        done

        echo "REQUIRED ACTIONS:"
        echo ""
        echo "1. Backup your data:"
        echo "   sudo ./backup-home.sh"
        echo ""
        echo "2. Create missing subvolumes (copy and run these commands):"
        echo ""

        # Generate commands grouped by device
        for device in "''${!DEVICE_SUBVOLS[@]}"; do
          echo "   # For device: $device"
          echo "   sudo mkdir -p /mnt"
          echo "   sudo mount -t btrfs -o subvolid=5 $device /mnt"
          for subvol in ''${DEVICE_SUBVOLS[$device]}; do
            echo "   sudo btrfs subvolume create /mnt/$subvol"
          done
          echo "   sudo umount /mnt"
          echo ""
        done

        echo "3. Migrate your data to the new subvolumes"
        echo ""
        echo "4. Rebuild your system:"
        echo "   sudo nixos-rebuild switch --flake .#nixos"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""

        # Return error code to make this visible in systemd status
        exit 1
      else
        echo "✅ All configured btrfs subvolumes exist"
        exit 0
      fi
    '';
  in
  {
    # Only enable validation if we have btrfs filesystems with subvolumes
    config = lib.mkIf (expectedSubvolumes != {}) {
      # Add check script to system packages
      environment.systemPackages = [ checkScript ];

      # Create a systemd service that runs the check early in boot
      systemd.services.btrfs-subvolume-check = {
        description = "Validate btrfs subvolumes exist";
        wantedBy = [ "multi-user.target" ];
        after = [ "local-fs.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${checkScript}/bin/check-btrfs-subvolumes";
          RemainAfterExit = true;
          # Don't fail boot, just warn
          SuccessExitStatus = [ 0 1 ];
        };
      };

      # Also provide a build-time warning
      warnings =
        let
          warningMsg = ''
            Your configuration references btrfs subvolumes that may not exist yet.
            Run 'systemctl status btrfs-subvolume-check' after boot to verify,
            or run 'check-btrfs-subvolumes' manually to check now.
          '';
        in
          lib.optional (expectedSubvolumes != {}) warningMsg;
    };
  };
}
