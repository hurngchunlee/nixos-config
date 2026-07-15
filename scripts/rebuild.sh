#!/usr/bin/env bash
# rebuild.sh — Rebuild for this host 
#
# Usage:
#   sudo bash scripts/rebuild.sh
#


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

HOSTNAME=$(hostname -s)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REPO_URL="https://github.com/dccn-tg/nixos-config"
REPO_DIR=$(cd "$SCRIPT_DIR/.." && git rev-parse --show-toplevel || "")

# ---------------------------------------------------------------------------
# 2. Clone this repository
# ---------------------------------------------------------------------------
if [ "$REPO_DIR" == "" ]; then
    REPO_DIR="/mnt/etc/nixos/nixos-config"
    info "Cloning nixos-config into $REPO_DIR"
    git clone "$REPO_URL" "$REPO_DIR"
    ok "Repository cloned"
fi

# ---------------------------------------------------------------------------
# 3. Copy generated hardware configuration into the repo
# ---------------------------------------------------------------------------

info "Checking host specific configuration"
if [ ! -f "$REPO_DIR/hosts/${HOSTNAME}.nix" ]; then
    sed s/@@HOSTNAME@@/${HOSTNAME}/g "$REPO_DIR/hosts/host.template" > "$REPO_DIR/hosts/${HOSTNAME}.nix"
    git add "$REPO_DIR/hosts/${HOSTNAME}.nix" 
fi

info "Copying hardware configuration to $REPO_DIR/hardware/generated/${HOSTNAME}.nix"
cp /etc/nixos/hardware-configuration.nix \
   "$REPO_DIR/hardware/generated/${HOSTNAME}.nix"
git add "$REPO_DIR/hardware/generated/${HOSTNAME}.nix"
ok "Hardware config copied"

# ---------------------------------------------------------------------------
# 4. Rebuild NixOS
# ---------------------------------------------------------------------------

info "Running nixos rebuild (this may take a while)"
nixos-rebuild switch --flake "${REPO_DIR}#${HOSTNAME}"
ok "NixOS rebuild complete"

# ---------------------------------------------------------------------------
# 13. Done
# ---------------------------------------------------------------------------

printf '\n'
printf '\033[1;32m====================================================\033[0m\n'
printf '\033[1;32m  Rebuild complete!\033[0m\n'
printf '\033[1;32m====================================================\033[0m\n'
printf '\n'
