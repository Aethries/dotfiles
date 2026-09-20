#!/usr/bin/env bash

# Read-only validation for bootstrap and fresh installation.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${DOTFILES_REPO_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"

info() {
    echo
    echo "==> $1"
}

success() {
    echo "✓ $1"
}

error() {
    echo "✗ $1" >&2
    exit 1
}

info "Running read-only preflight..."

MODE="${1:-bootstrap}"
case "$MODE" in
    bootstrap)
        REQUIRED_TOOLS=(nix nixos-generate-config sudo)
        ;;
    installer)
        REQUIRED_TOOLS=(
            nix nix-shell nixos-generate-config nixos-install ping hostname
            lsblk wipefs parted mkfs.fat mkfs.ext4 mount umount findmnt swapoff swapon mkswap
            partprobe chown cp
        )
        ;;
    *)
        error "Unknown preflight mode: $MODE (expected bootstrap or installer)."
        ;;
esac

for tool in "${REQUIRED_TOOLS[@]}"; do
    command -v "$tool" >/dev/null 2>&1 || error "Required tool is not available: $tool"
done

[ "$(uname -m)" = "x86_64" ] \
    || error "Unsupported architecture. This repository currently supports x86_64-linux only."

for required_file in \
    "$REPO_ROOT/flake.lock" \
    "$REPO_ROOT/resources/ai/gateway.env" \
    "$REPO_ROOT/resources/certs/9router-rootCA.crt"; do
    [ -f "$required_file" ] || error "Required repository file is missing: $required_file"
done

HOSTS_MODULE="$REPO_ROOT/modules/services/ai-gateways.nix"
[ -f "$HOSTS_MODULE" ] || error "AI gateway host mapping module is missing: $HOSTS_MODULE"
for host in daily-cloudcode-pa.googleapis.com cloudcode-pa.googleapis.com; do
    grep -Fq "127.0.0.1 $host" "$HOSTS_MODULE" \
        || error "Required declarative host mapping is missing: $host"
done

nix flake check "path:$REPO_ROOT" --no-build >/dev/null \
    || error "Read-only flake preflight failed. No filesystem mutation was performed."

success "Preflight passed; no repository or machine state was modified."
