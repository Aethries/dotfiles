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
	if [[ "$(uname -m)" == "x86_64" ]]; then
		log "Installing Neovide binary (x86_64)"
		mkdir -p "$HOME/.local/bin"
		tmp_tar="$(mktemp "/tmp/neovide_XXXXXX.tar")"
		if curl -sL https://github.com/neovide/neovide/releases/download/0.16.2/neovide-linux-x86_64.tar -o "$tmp_tar"; then
			tar -xf "$tmp_tar" -C "$HOME/.local/bin" && chmod +x "$HOME/.local/bin/neovide"
			rm -f "$tmp_tar"
			success "Neovide installed to ~/.local/bin/neovide"
		else
			rm -f "$tmp_tar"
			warn "Failed to download Neovide binary"
		fi
	else
		warn "Neovide prebuilt binary only configured for x86_64 architecture ($(uname -m) detected)"
	fi
fi

if [[ ! -f "$MODULE_DIR/files/lua/lua-utf8.so" ]] && command_exists gcc; then
	log "Compiling lua-utf8 extension for Unicode/Vietnamese support"
	tmp_build="$(mktemp -d "/tmp/luautf8_XXXXXX")"
	if curl -sSL https://raw.githubusercontent.com/starwing/luautf8/master/lutf8lib.c -o "$tmp_build/lutf8lib.c" && \
	   curl -sSL https://raw.githubusercontent.com/starwing/luautf8/master/unidata.h -o "$tmp_build/unidata.h"; then
		mkdir -p "$MODULE_DIR/files/lua"
		gcc -O2 -fPIC -shared -I/usr/include/luajit-2.1 "$tmp_build/lutf8lib.c" -o "$MODULE_DIR/files/lua/lua-utf8.so" 2>/dev/null || true
		rm -rf "$tmp_build"
		if [[ -f "$MODULE_DIR/files/lua/lua-utf8.so" ]]; then
			success "lua-utf8 compiled"
		else
			warn "lua-utf8 compilation failed (missing luajit headers?)"
		fi
	else
		rm -rf "$tmp_build"
		warn "Failed to download lua-utf8 sources"
	fi
fi

if command_exists nvim && command_exists git; then
	log "Syncing Neovim plugins via Lazy.nvim"
	nvim --headless "+Lazy! sync" +qa 2>/dev/null || warn "Lazy sync encountered warnings (plugins will install on first open)"
	success "Neovim plugins synced"
fi

success "Neovim configured"
