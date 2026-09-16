#!/usr/bin/env bash

set -euo pipefail

info() {
    echo
    echo "==> $1"
}

success() {
    echo "✓ $1"
}

warn() {
    echo "! $1"
}

error() {
    echo "✗ $1" >&2
    exit 1
}

info "Checking disk usage of /nix before cleanup..."
df -h /nix || true

info "Step 1/3: Deleting old user-profile generations..."
nix-collect-garbage --delete-old || true

info "Step 2/3: Deleting old system generations (all older than current)..."
sudo nix-collect-garbage -d

# Update boot menu so deleted generations are removed from systemd-boot/grub
if [ -x /run/current-system/bin/switch-to-configuration ]; then
    info "Updating bootloader menu..."
    sudo /run/current-system/bin/switch-to-configuration boot || true
fi

info "Step 3/3: Optimizing Nix store (deduplicating identical files)..."
sudo nix-store --optimise

info "Disk usage of /nix after cleanup:"
df -h /nix || true

success "NixOS cleanup completed successfully!"
