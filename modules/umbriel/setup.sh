#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Configuring umbriel"

mkdir -p "$HOME/.config/umbriel"

link_file \
	"$MODULE_DIR/files/config.toml" \
	"$HOME/.config/umbriel/config.toml"

link_file \
	"$MODULE_DIR/files/keybinds.toml" \
	"$HOME/.config/umbriel/keybinds.toml"


success "Umbriel configured"
