#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Setting up Audio Effects (EasyEffects & Presets)"

mkdir -p "$HOME/.config/easyeffects/output"
mkdir -p "$HOME/.config/systemd/user"

# Link presets
for preset in "$MODULE_DIR"/files/presets/*.json; do
	preset_name="$(basename "$preset")"
	link_file "$preset" "$HOME/.config/easyeffects/output/$preset_name"
done

# Link systemd user service
link_file \
	"$MODULE_DIR/files/easyeffects.service" \
	"$HOME/.config/systemd/user/easyeffects.service"

# Link init-mixer binary & mixer alias
mkdir -p "$HOME/.local/bin"
link_file \
	"$MODULE_DIR/files/bin/init-mixer" \
	"$HOME/.local/bin/init-mixer"
chmod +x "$MODULE_DIR/files/bin/init-mixer"
chmod +x "$HOME/.local/bin/init-mixer" 2>/dev/null || true

link_file \
	"$MODULE_DIR/files/bin/init-mixer" \
	"$HOME/.local/bin/mixer"
chmod +x "$HOME/.local/bin/mixer" 2>/dev/null || true

if command_exists systemctl; then
	systemctl --user daemon-reload
	if command_exists easyeffects; then
		systemctl --user enable easyeffects.service
		systemctl --user restart easyeffects.service || true
	fi
fi

success "EasyEffects presets and service configured"
