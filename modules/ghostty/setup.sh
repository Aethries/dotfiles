#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Setting up Ghostty terminal"

mkdir -p "$HOME/.config/ghostty"
mkdir -p "$HOME/.config/ghostty/shaders"

link_file \
	"$MODULE_DIR/files/config" \
	"$HOME/.config/ghostty/config"

link_dir \
	"$MODULE_DIR/files/shaders" \
	"$HOME/.config/ghostty/shaders"

success "Ghostty configured"
