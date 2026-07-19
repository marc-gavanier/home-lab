#!/usr/bin/env bash
# =============================================================================
# Home Lab — LUKS header backup (run ON THE PI, as root)
# =============================================================================
# The 5 TB data disk is a single LUKS container. If its header is damaged (bad
# sector, botched cryptsetup op), ALL of /mnt/data is unrecoverable EVEN WITH
# the correct passphrase — taking the live data AND the local restic repo with
# it (only the offsite repo survives). The header is 2-16 MB.
#
# This produces a header backup file. It deliberately does NOT store it: the
# header is as sensitive as the passphrase (header + passphrase = data). YOU
# must move it OFF this machine — attach it to Vaultwarden AND an offline USB
# key, then shred the working copy. See knowledge/runbooks/luks-header-backup.md.
#
# Re-run after ANY cryptsetup change (added/removed keyslot, luksChangeKey).
#
# Usage:  sudo ./luks-header-backup.sh [LUKS_DEVICE]   (default: /dev/sda1)
# =============================================================================

set -euo pipefail

DEVICE="${1:-/dev/sda1}"
OUT="/tmp/luks-header-${DEVICE//\//_}-$(date +%Y%m%d-%H%M%S).img"

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: run as root (needs raw access to $DEVICE)" >&2
    exit 1
fi

if ! cryptsetup isLuks "$DEVICE"; then
    echo "ERROR: $DEVICE is not a LUKS device" >&2
    exit 1
fi

umask 077
cryptsetup luksHeaderBackup "$DEVICE" --header-backup-file "$OUT"
chmod 600 "$OUT"

echo
echo "Header backed up to: $OUT"
echo "SHA256: $(sha256sum "$OUT" | cut -d' ' -f1)"
echo "Size:   $(du -h "$OUT" | cut -f1)"
echo
echo "NEXT (this file is as sensitive as the passphrase — do NOT leave it here):"
echo "  1. Attach it to a secure note in Vaultwarden (your offsite password vault)."
echo "  2. Copy it to an OFFLINE USB key kept off-site."
echo "  3. Shred the working copy:  shred -u '$OUT'"
