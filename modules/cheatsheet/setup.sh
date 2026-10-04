#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Configuring cheatsheet"

chmod +x "$MODULE_DIR/files/sys-cheatsheet"

# Link executable to ~/.local/bin
link_file \
	"$MODULE_DIR/files/sys-cheatsheet" \
	"$HOME/.local/bin/sys-cheatsheet"

# Link database to ~/.config/cheatsheet/keymaps.tsv
mkdir -p "$HOME/.config/cheatsheet"
link_file \
	"$MODULE_DIR/files/keymaps.tsv" \
	"$HOME/.config/cheatsheet/keymaps.tsv"

success "Cheatsheet configured"
