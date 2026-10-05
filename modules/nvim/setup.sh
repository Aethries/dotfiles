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

link_file \
	"$MODULE_DIR/files/neovide.toml" \
	"$HOME/.config/neovide/config.toml"

# Noctalia setup registers our template from ~/.config/nvim directly.
# Community cache paths are intentionally not part of the installation contract.

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

if [[ ! -f "$MODULE_DIR/files/lua/lua-utf8.so" ]] && command_exists gcc; then
	log "Compiling lua-utf8 extension for Unicode/Vietnamese support"
	mkdir -p /tmp/luautf8_build
	if curl -sSL https://raw.githubusercontent.com/starwing/luautf8/master/lutf8lib.c -o /tmp/luautf8_build/lutf8lib.c && \
	   curl -sSL https://raw.githubusercontent.com/starwing/luautf8/master/unidata.h -o /tmp/luautf8_build/unidata.h; then
		gcc -O2 -fPIC -shared -I/usr/include/luajit-2.1 /tmp/luautf8_build/lutf8lib.c -o "$MODULE_DIR/files/lua/lua-utf8.so" 2>/dev/null || true
		rm -rf /tmp/luautf8_build
		success "lua-utf8 compiled"
	fi
fi

if command_exists nvim && command_exists git; then
	log "Syncing Neovim plugins via Lazy.nvim"
	nvim --headless "+Lazy! sync" +qa 2>/dev/null || warn "Lazy sync encountered warnings (plugins will install on first open)"
	success "Neovim plugins synced"
fi

success "Neovim configured"
