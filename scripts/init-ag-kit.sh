#!/usr/bin/env bash
# ==============================================================================
# scripts/init-ag-kit.sh
# Safely initialize or update Antigravity Kit (.agents) in dotfiles repository.
# Follows official AG Kit documentation (https://ag-kit.unikorn.vn/docs/installation).
# ==============================================================================

set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

info() {
    echo -e "${BLUE}${BOLD}==>${NC} ${BOLD}$1${NC}"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warn() {
    echo -e "${YELLOW}!${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1" >&2
    exit 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${DOTFILES_REPO_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"

if ! command -v npx >/dev/null 2>&1; then
    warn "npx is not available in PATH. Skipping Antigravity Kit synchronization."
    exit 0
fi

cd "$REPO_ROOT"

info "Synchronizing Antigravity Kit (@vudovn/ag-kit)..."

# If managed tree manifest exists, run update with merge strategy; otherwise init
if [ -f "$REPO_ROOT/.agents/.ag-kit/manifest.json" ]; then
    npx -y @vudovn/ag-kit@latest update --strategy merge --force "$@"
else
    npx -y @vudovn/ag-kit@latest init --strategy merge --force "$@"
fi

# Ensure correct file permissions for target user when invoked under sudo
TARGET_USER="${SUDO_USER:-$(id -un)}"
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    chown -R "$TARGET_USER:" "$REPO_ROOT/.agents" 2>/dev/null || true
fi

success "Antigravity Kit synchronized successfully."
