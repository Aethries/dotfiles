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
df -h /nix || true # BEST_EFFORT: disk reporting is informational and must not mask garbage collection.

info "Step 1/3: Deleting old user-profile generations..."
nix-collect-garbage --delete-old || true # BEST_EFFORT: garbage collection is maintenance-only; a failed cleanup must not block the rest of the report.

info "Step 2/3: Deleting old system generations (all older than current)..."
sudo nix-collect-garbage -d

# Update boot menu so deleted generations are removed from systemd-boot/grub
if [ -x /run/current-system/bin/switch-to-configuration ]; then
    info "Updating bootloader menu..."
    sudo /run/current-system/bin/switch-to-configuration boot || true # BEST_EFFORT: boot-menu refresh is optional after generation cleanup.
fi

info "Step 3/3: Optimizing Nix store (deduplicating identical files)..."
sudo nix-store --optimise

info "Disk usage of /nix after cleanup:"
df -h /nix || true # BEST_EFFORT: final disk reporting is informational after cleanup.

success "NixOS cleanup completed successfully!"
