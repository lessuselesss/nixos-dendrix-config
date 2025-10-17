#!/usr/bin/env bash
set -e

# Backup /home before impermanence setup
# This preserves all user data before switching to btrfs subvolumes

BACKUP_DIR="/nix/backup/home-pre-impermanence-$(date +%Y%m%d-%H%M%S)"
LOG_FILE="/tmp/home-backup.log"

echo "========================================="
echo "Home Directory Backup for Impermanence"
echo "========================================="
echo ""
echo "Source: /home"
echo "Destination: $BACKUP_DIR"
echo "Size: $(du -sh /home 2>/dev/null | cut -f1)"
echo ""
read -p "Continue with backup? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

# Create backup directory
echo "Creating backup directory..."
mkdir -p "$BACKUP_DIR"

# Backup with rsync (preserves permissions, symlinks, etc.)
echo "Starting rsync backup..."
echo "This may take several minutes for 13GB..."
rsync -aAXv \
    --info=progress2 \
    --exclude='.cache' \
    --exclude='.local/share/Trash' \
    /home/ \
    "$BACKUP_DIR/" \
    2>&1 | tee "$LOG_FILE"

# Verify backup
echo ""
echo "Verifying backup..."
ORIGINAL_SIZE=$(du -sb /home | cut -f1)
BACKUP_SIZE=$(du -sb "$BACKUP_DIR" | cut -f1)
DIFF=$((ORIGINAL_SIZE - BACKUP_SIZE))

echo "Original size: $(numfmt --to=iec $ORIGINAL_SIZE)"
echo "Backup size:   $(numfmt --to=iec $BACKUP_SIZE)"
echo "Difference:    $(numfmt --to=iec ${DIFF#-}) (expected due to excluded cache)"

# Create checksums for important files
echo ""
echo "Creating checksums for verification..."
cd "$BACKUP_DIR"
find . -type f -name '*.ssh' -o -name '*.gpg' -o -name '*.age' -o -name 'secrets.yaml' 2>/dev/null | \
    xargs -r sha256sum > "$BACKUP_DIR/CHECKSUMS.sha256" 2>/dev/null || true

# Create backup manifest
echo "Creating backup manifest..."
cat > "$BACKUP_DIR/BACKUP_INFO.txt" << EOF
Backup Created: $(date)
Original Location: /home
Backup Location: $BACKUP_DIR
Original Size: $(numfmt --to=iec $ORIGINAL_SIZE)
Backup Size: $(numfmt --to=iec $BACKUP_SIZE)
Hostname: $(hostname)
User: $(whoami)

Purpose: Pre-impermanence backup before btrfs subvolume migration

Files Backed Up:
$(find "$BACKUP_DIR" -type f | wc -l) files
$(find "$BACKUP_DIR" -type d | wc -l) directories

Log: $LOG_FILE
Checksums: $BACKUP_DIR/CHECKSUMS.sha256

To restore:
  sudo rsync -aAXv $BACKUP_DIR/ /home/

EOF

cat "$BACKUP_DIR/BACKUP_INFO.txt"

echo ""
echo "✅ Backup complete!"
echo "Backup location: $BACKUP_DIR"
echo "Log file: $LOG_FILE"
echo ""
echo "Next steps:"
echo "  1. Verify backup: ls -la $BACKUP_DIR"
echo "  2. Create btrfs subvolumes"
echo "  3. Rebuild with impermanence enabled"
