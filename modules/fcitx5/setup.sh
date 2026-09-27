#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Setting up Fcitx5 Vietnamese input method"

mkdir -p "$HOME/.config/fcitx5"
mkdir -p "$HOME/.config/environment.d"

link_file \
	"$MODULE_DIR/files/profile" \
	"$HOME/.config/fcitx5/profile"

link_file \
	"$MODULE_DIR/files/config" \
	"$HOME/.config/fcitx5/config"

link_dir \
	"$MODULE_DIR/files/conf" \
	"$HOME/.config/fcitx5/conf"

link_file \
	"$MODULE_DIR/files/10-fcitx5.conf" \
	"$HOME/.config/environment.d/10-fcitx5.conf"

success "Fcitx5 configured"
