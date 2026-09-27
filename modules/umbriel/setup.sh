#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Configuring umbriel"

# Umbriel
if [[ ! -d "$HOME/.config/umbriel" ]]; then
	mkdir -p "$HOME/.config/umbriel"
fi

# Config
link_file \
	"$MODULE_DIR/files/config.toml" \
	"$HOME/.config/umbriel/config.toml"

link_file \
	"$MODULE_DIR/files/appearance.toml" \
	"$HOME/.config/umbriel/appearance.toml"

link_file \
	"$MODULE_DIR/files/keybinds.toml" \
	"$HOME/.config/umbriel/keybinds.toml"

link_file \
	"$MODULE_DIR/files/noctalia.toml" \
	"$HOME/.config/umbriel/noctalia.toml"

link_file \
	"$MODULE_DIR/files/chrome-flags.conf" \
	"$HOME/.config/chrome-flags.conf"

success "Umbriel configured"
