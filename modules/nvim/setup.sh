#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Configuring Neovim"

mkdir -p "$HOME/.config"

link_dir \
	"$MODULE_DIR/files" \
	"$HOME/.config/nvim"

if command_exists nvim && command_exists git; then
	log "Syncing Neovim plugins via Lazy.nvim"
	nvim --headless "+Lazy! sync" +qa 2>/dev/null || warn "Lazy sync encountered warnings (plugins will install on first open)"
	success "Neovim plugins synced"
fi

success "Neovim configured"
