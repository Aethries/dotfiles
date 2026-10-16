#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Configuring noctalia"

mkdir -p "$HOME/.config/noctalia"
mkdir -p "$HOME/.local/state/noctalia"

link_file \
	"$MODULE_DIR/files/config.toml" \
	"$HOME/.config/noctalia/config.toml"

link_file \
	"$MODULE_DIR/files/templates.toml" \
	"$HOME/.config/noctalia/templates.toml"

if [[ -d "$MODULE_DIR/files/plugins" ]] && [[ -n "$(ls -A "$MODULE_DIR/files/plugins" 2>/dev/null | grep -v '^\.gitkeep$' || true)" ]]; then
	link_dir \
		"$MODULE_DIR/files/plugins" \
		"$HOME/.config/noctalia/plugins"
else
	mkdir -p "$HOME/.config/noctalia/plugins"
fi

if [[ -d "$MODULE_DIR/files/palettes" ]]; then
	link_dir \
		"$MODULE_DIR/files/palettes" \
		"$HOME/.config/noctalia/palettes"
fi

if [[ -f "$MODULE_DIR/files/settings.toml" ]]; then
	sed -i -E "s|@HOME@|$HOME|g" "$MODULE_DIR/files/settings.toml"
	sed -i -E "s|/home/[a-zA-Z0-9._-]+/Pictures/|$HOME/Pictures/|g" "$MODULE_DIR/files/settings.toml"
fi

link_file \
	"$MODULE_DIR/files/settings.toml" \
	"$HOME/.local/state/noctalia/settings.toml"

if [[ -d "$DOTFILES/resources/static/wallpapers" ]]; then
	mkdir -p "$HOME/Pictures"
	link_dir \
		"$DOTFILES/resources/static/wallpapers" \
		"$HOME/Pictures/Wallpapers"

	for wp in "$DOTFILES/resources/static/wallpapers"/*; do
		if [[ -f "$wp" ]]; then
			wp_name="$(basename "$wp")"
			link_file "$wp" "$HOME/Pictures/$wp_name"
		fi
	done
fi

# Hide unwanted applications from Noctalia launcher
if [[ -f "$MODULE_DIR/files/hidden-apps.txt" ]]; then
	log "Hiding unwanted apps from launcher"
	mkdir -p "$HOME/.local/share/applications"
	while read -r app; do
		[[ -z "$app" || "$app" =~ ^# ]] && continue
		desktop_file="$HOME/.local/share/applications/$app"
		cat << EOF > "$desktop_file"
[Desktop Entry]
Type=Application
Name=$app
NoDisplay=true
Hidden=true
EOF
	done < "$MODULE_DIR/files/hidden-apps.txt"

	if command_exists update-desktop-database; then
		update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
	fi
	success "Unwanted apps hidden from launcher"
fi

success "Noctalia configured"
