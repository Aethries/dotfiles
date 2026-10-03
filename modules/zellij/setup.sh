#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Setting up Zellij terminal multiplexer"

mkdir -p "$HOME/.config/zellij"

chmod +x "$MODULE_DIR/files/scripts/launcher.sh"

link_file \
	"$MODULE_DIR/files/config.kdl" \
	"$HOME/.config/zellij/config.kdl"

link_dir \
	"$MODULE_DIR/files/layouts" \
	"$HOME/.config/zellij/layouts"

link_dir \
	"$MODULE_DIR/files/scripts" \
	"$HOME/.config/zellij/scripts"

link_dir \
	"$MODULE_DIR/files/themes" \
	"$HOME/.config/zellij/themes"

success "Zellij configured"
