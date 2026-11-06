#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Setting up vault and browser credentials integration"

mkdir -p "$HOME/.config"

link_file \
	"$MODULE_DIR/files/chrome-flags.conf" \
	"$HOME/.config/chrome-flags.conf"
link_file \
	"$MODULE_DIR/files/chrome-flags.conf" \
	"$HOME/.config/chromium-flags.conf"

# Link vault CLI
mkdir -p "$HOME/.local/bin"
link_file \
	"$DOTFILES/scripts/vault.sh" \
	"$HOME/.local/bin/vault"
chmod +x "$HOME/.local/bin/vault"

success "Vault integration configured"
