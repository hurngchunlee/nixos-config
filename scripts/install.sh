#!/usr/bin/env bash
# install.sh — Unattended NixOS installation from this flake.
#
# Usage:
#   sudo bash scripts/install.sh <hostname> <disk-device>
#
# Examples:
#   sudo bash scripts/install.sh vm001 /dev/vda
#   sudo bash scripts/install.sh dccnlpt001 /dev/nvme0n1
#
# The script follows every step documented in README.md:
#   1.  Validate inputs
#   2.  Prompt for LUKS passphrase and nixadmin password (once, at the start)
#   3.  Confirm before wiping the disk
#   4.  Partition the disk (GPT: 512 MB ESP + rest as root)
#   5.  Set up LUKS encryption on the root partition
#   6.  Format partitions (FAT32 ESP, XFS root labelled "nixos")
#   7.  Mount filesystems
#   8.  Generate hardware configuration
#   9.  Clone this repository into /mnt/etc/nixos/nixos-config
#   10. Copy the generated hardware config into the repo
#   11. Install NixOS (no root password)
#   12. Set the nixadmin user password
#   13. Print reboot notice

set -euo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

info()  { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
ok()    { printf '\033[1;32m  ✓\033[0m %s\n' "$*"; }
die()   { printf '\n\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# 1. Input validation
# ---------------------------------------------------------------------------

[[ $EUID -eq 0 ]] || die "This script must be run as root (use sudo)."

HOSTNAME="${1:-}"
DISK="${2:-}"

[[ -n "$HOSTNAME" ]] || die "Usage: $0 <hostname> <disk-device>"
[[ -n "$DISK"     ]] || die "Usage: $0 <hostname> <disk-device>"
[[ -b "$DISK"     ]] || die "Disk device '$DISK' not found or is not a block device."

# Derive partition names — handle both /dev/sdX and /dev/nvmeXnY style devices.
if [[ "$DISK" =~ nvme|loop|mmcblk ]]; then
    PART_ESP="${DISK}p1"
    PART_ROOT="${DISK}p2"
else
    PART_ESP="${DISK}1"
    PART_ROOT="${DISK}2"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REPO_URL="https://github.com/dccn-tg/nixos-config"
REPO_DIR=$(cd "$SCRIPT_DIR/.." && git rev-parse --show-toplevel || "")

# ---------------------------------------------------------------------------
# 2. Collect secrets up front (nothing is written to disk or echoed)
# ---------------------------------------------------------------------------

info "Collecting secrets"

read -rsp "  Enter LUKS passphrase: " LUKS_PASS; echo
read -rsp "  Confirm LUKS passphrase: " LUKS_PASS2; echo
[[ "$LUKS_PASS" == "$LUKS_PASS2" ]] || die "LUKS passphrases do not match."
[[ ${#LUKS_PASS} -ge 8 ]] || die "LUKS passphrase must be at least 8 characters."

read -rsp "  Enter password for user 'nixadmin': " USER_PASS; echo
read -rsp "  Confirm password for user 'nixadmin': " USER_PASS2; echo
[[ "$USER_PASS" == "$USER_PASS2" ]] || die "User passwords do not match."
[[ ${#USER_PASS} -ge 6 ]] || die "User password must be at least 6 characters."

# ---------------------------------------------------------------------------
# 3. Confirmation prompt
# ---------------------------------------------------------------------------

printf '\n'
printf '\033[1;33mWARNING:\033[0m All data on %s will be permanently destroyed.\n' "$DISK"
printf '         Hostname : %s\n' "$HOSTNAME"
printf '         Disk     : %s\n' "$DISK"
printf '         ESP      : %s\n' "$PART_ESP"
printf '         Root     : %s  (LUKS → /dev/mapper/cryptroot → XFS "nixos")\n' "$PART_ROOT"
printf '\n'
read -rp "Type YES in uppercase to continue: " CONFIRM
[[ "$CONFIRM" == "YES" ]] || { echo "Aborted."; exit 0; }

# ---------------------------------------------------------------------------
# 4. Partition the disk
# ---------------------------------------------------------------------------

info "Partitioning $DISK"
parted -s "$DISK" -- mklabel gpt
parted -s "$DISK" -- mkpart ESP fat32 1MB 512MB
parted -s "$DISK" -- set 1 esp on
parted -s "$DISK" -- mkpart primary 512MB 100%
ok "Partitions created"

# Give the kernel a moment to register the new partition table.
sleep 1
partprobe "$DISK" 2>/dev/null || true

# ---------------------------------------------------------------------------
# 5. Set up LUKS encryption
# ---------------------------------------------------------------------------

info "Setting up LUKS on $PART_ROOT"
printf '%s' "$LUKS_PASS" | cryptsetup luksFormat \
    --batch-mode \
    --key-file=- \
    "$PART_ROOT"

printf '%s' "$LUKS_PASS" | cryptsetup open \
    --key-file=- \
    "$PART_ROOT" cryptroot

ok "LUKS container opened at /dev/mapper/cryptroot"

# Passphrase is no longer needed; overwrite the variable.
LUKS_PASS="$(head -c 64 /dev/urandom | base64)"
LUKS_PASS2="$LUKS_PASS"

# ---------------------------------------------------------------------------
# 6. Format partitions
# ---------------------------------------------------------------------------

info "Formatting partitions"
mkfs.fat -F 32 -n boot "$PART_ESP"
mkfs.xfs -L nixos /dev/mapper/cryptroot
ok "FAT32 ESP and XFS root formatted"

# ---------------------------------------------------------------------------
# 7. Mount filesystems (wait for udev to settle)
# ---------------------------------------------------------------------------

udevadm settle

info "Mounting filesystems"
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount "$PART_ESP" /mnt/boot
ok "Filesystems mounted at /mnt"

# ---------------------------------------------------------------------------
# 8. Generate hardware configuration
# ---------------------------------------------------------------------------

info "Generating hardware configuration"
nixos-generate-config --root /mnt
ok "Hardware configuration written to /mnt/etc/nixos/"

# ---------------------------------------------------------------------------
# 9. Clone this repository
# ---------------------------------------------------------------------------
if [ "$REPO_DIR" == "" ]; then
    REPO_DIR="/mnt/etc/nixos/nixos-config"
    info "Cloning nixos-config into $REPO_DIR"
    git clone "$REPO_URL" "$REPO_DIR"
    ok "Repository cloned"
fi

# ---------------------------------------------------------------------------
# 10. Copy generated hardware configuration into the repo
# ---------------------------------------------------------------------------

info "Copying hardware configuration to $REPO_DIR/hardware/generated/${HOSTNAME}.nix"
cp /mnt/etc/nixos/hardware-configuration.nix \
   "$REPO_DIR/hardware/generated/${HOSTNAME}.nix"
ok "Hardware config copied"

# ---------------------------------------------------------------------------
# 11. Install NixOS
# ---------------------------------------------------------------------------

info "Running nixos-install (this may take a while)"
nixos-install --no-root-passwd --flake "${REPO_DIR}#${HOSTNAME}"
ok "NixOS installation complete"

# ---------------------------------------------------------------------------
# 12. Set nixadmin password
# ---------------------------------------------------------------------------

info "Setting password for user 'nixadmin'"
nixos-enter --root /mnt -c \
    "printf '%s\n%s\n' '${USER_PASS}' '${USER_PASS}' | passwd nixadmin"

# Overwrite the password variable now that it has been used.
USER_PASS="$(head -c 64 /dev/urandom | base64)"
USER_PASS2="$USER_PASS"

ok "Password set for nixadmin"

# ---------------------------------------------------------------------------
# 13. Done
# ---------------------------------------------------------------------------

printf '\n'
printf '\033[1;32m====================================================\033[0m\n'
printf '\033[1;32m  Installation complete!\033[0m\n'
printf '\033[1;32m====================================================\033[0m\n'
printf '\n'
printf '  Next steps:\n'
printf '    1. Remove the installer media.\n'
printf '    2. Run: reboot\n'
printf '    3. Enter the LUKS passphrase when prompted by the bootloader.\n'
printf '    4. Log in as nixadmin with the password you just set.\n'
printf '    5. Change your password immediately: passwd\n'
printf '\n'
