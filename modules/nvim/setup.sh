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

success "Neovim configured"
