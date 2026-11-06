#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Configuring matugen (Material 3 color synchronization)"

MATUGEN_DIR="$HOME/.config/matugen"

mkdir -p \
	"$MATUGEN_DIR" \
	"$HOME/.config/ghostty/themes" \
	"$HOME/.config/zellij/themes" \
	"$HOME/.local/share/fcitx5/themes/matugen" \
	"$HOME/.config/fuzzel" \
	"$HOME/.config/gtk-3.0" \
	"$HOME/.config/gtk-4.0" \
	"${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/user/generated/wallpaper"

link_dir \
	"$MODULE_DIR/files/templates" \
	"$MATUGEN_DIR/templates"

# Quickshell reads config.toml.orig as the source of truth and rewrites
# config.toml when templates are enabled/disabled. Keep the repo copy at .orig
# and use a regular file for the generated config so git stays clean.
link_file \
	"$MODULE_DIR/files/config.toml" \
	"$MATUGEN_DIR/config.toml.orig"

if [[ ! -e "$MATUGEN_DIR/config.toml" ]]; then
	cp "$MODULE_DIR/files/config.toml" "$MATUGEN_DIR/config.toml"
	echo " $MATUGEN_DIR/config.toml (seeded)"
fi

success "matugen configured"
