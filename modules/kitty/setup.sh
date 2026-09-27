#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Setting up kitty terminal"

mkdir -p "$HOME/.config/kitty"

link_file \
	"$MODULE_DIR/files/kitty.conf" \
	"$HOME/.config/kitty/kitty.conf"

success "Kitty configured"
