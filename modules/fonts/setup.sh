#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Setting up fonts and fontconfig"

mkdir -p "$HOME/.config/fontconfig"

link_file \
	"$MODULE_DIR/files/fonts.conf" \
	"$HOME/.config/fontconfig/fonts.conf"

if command_exists fc-cache; then
	log "Updating font cache"
	fc-cache -f "$HOME/.local/share/fonts" 2>/dev/null || fc-cache -f 2>/dev/null || true
	success "Font cache updated"
fi

success "Fonts configured"
