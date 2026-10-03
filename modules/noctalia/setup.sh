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
	"$MODULE_DIR/files/plugins" \
	"$HOME/.config/noctalia/plugins"

link_file \
	"$MODULE_DIR/files/settings.toml" \
	"$HOME/.local/state/noctalia/settings.toml"

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
