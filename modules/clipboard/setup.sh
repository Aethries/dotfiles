#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Setting up Clipboard Manager (cliphist)"

mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.config/systemd/user"

link_file \
	"$MODULE_DIR/files/cliphist-picker.sh" \
	"$HOME/.local/bin/cliphist-picker"

chmod +x "$MODULE_DIR/files/cliphist-picker.sh"
chmod +x "$HOME/.local/bin/cliphist-picker" 2>/dev/null || true

link_file \
	"$MODULE_DIR/files/cliphist.service" \
	"$HOME/.config/systemd/user/cliphist.service"

if command_exists systemctl; then
	systemctl --user daemon-reload
	systemctl --user enable cliphist.service
	systemctl --user restart cliphist.service || true
fi

success "Clipboard Manager configured"
