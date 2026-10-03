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

if [[ -d "$HOME/.local/state/noctalia/community-templates/neovim" ]]; then
	link_file \
		"$MODULE_DIR/files/matugen-template.lua" \
		"$HOME/.local/state/noctalia/community-templates/neovim/matugen-template.lua"
fi

if ! command_exists neovide; then
	log "Installing Neovide binary"
	mkdir -p "$HOME/.local/bin"
	if curl -sL https://github.com/neovide/neovide/releases/download/0.16.2/neovide-linux-x86_64.tar -o /tmp/neovide.tar; then
		tar -xf /tmp/neovide.tar -C "$HOME/.local/bin" && chmod +x "$HOME/.local/bin/neovide"
		rm -f /tmp/neovide.tar
		success "Neovide installed to ~/.local/bin/neovide"
	else
		warn "Failed to download Neovide binary"
	fi
fi

if command_exists nvim && command_exists git; then
	log "Syncing Neovim plugins via Lazy.nvim"
	nvim --headless "+Lazy! sync" +qa 2>/dev/null || warn "Lazy sync encountered warnings (plugins will install on first open)"
	success "Neovim plugins synced"
fi

success "Neovim configured"
