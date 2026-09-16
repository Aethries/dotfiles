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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MACHINE_CONFIG="$REPO_ROOT/.machine/configuration.nix"

ACTION="${1:-switch}"
shift 2>/dev/null || true

case "$ACTION" in
    switch|boot|test|build|dry-build|dry-activate)
        ;;
    *)
        error "Unknown action: '$ACTION'. Valid options: switch, boot, test, build, dry-build, dry-activate"
        ;;
esac

if [ ! -f "$MACHINE_CONFIG" ]; then
    error "Machine configuration not found at $MACHINE_CONFIG. Please run ./scripts/bootstrap.sh first."
fi

# 1. Tự động sinh keymap Antigravity & docs từ manifest
if command -v nvim >/dev/null 2>&1 && [ -f "$REPO_ROOT/scripts/generate-keymaps.lua" ]; then
    info "Generating unified keymaps..."
    nvim -l "$REPO_ROOT/scripts/generate-keymaps.lua" >/dev/null 2>&1 || warn "Could not generate keymaps automatically"
fi

# 2. Tạo snapshot rollback trước khi rebuild
BACKUP_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/backup-latest"
mkdir -p "$BACKUP_DIR"
if [ -d "$HOME/.config/antigravity" ]; then
    cp -r "$HOME/.config/antigravity" "$BACKUP_DIR/" 2>/dev/null || true
fi
if [ -d "$HOME/.config/nvim" ]; then
    cp -r "$HOME/.config/nvim" "$BACKUP_DIR/" 2>/dev/null || true
fi

rollback_on_error() {
    warn "Build encountered an error. Restoring from snapshot in $BACKUP_DIR if needed."
}
trap rollback_on_error ERR

info "Building and applying NixOS configuration ($ACTION)..."
echo "  Configuration : $MACHINE_CONFIG"
echo "  Action        : $ACTION"

sudo nixos-rebuild "$ACTION" \
    -I "nixos-config=$MACHINE_CONFIG" \
    "$@"

if [ "$ACTION" = "switch" ] || [ "$ACTION" = "test" ]; then
    info "Synchronizing editor configuration from the repository..."
    "$REPO_ROOT/scripts/sync-editors.sh"
fi

trap - ERR

success "NixOS configuration ($ACTION) completed successfully!"
