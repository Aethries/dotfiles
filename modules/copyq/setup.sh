#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Setting up CopyQ Clipboard Manager with Noctalia Theme"

mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.config/copyq/themes"
mkdir -p "$HOME/.config/systemd/user"

link_file \
	"$MODULE_DIR/files/copyq-toggle.sh" \
	"$HOME/.local/bin/copyq-toggle"

chmod +x "$MODULE_DIR/files/copyq-toggle.sh"
chmod +x "$HOME/.local/bin/copyq-toggle" 2>/dev/null || true

link_file \
	"$MODULE_DIR/files/copyq.conf" \
	"$HOME/.config/copyq/copyq.conf"

link_file \
	"$MODULE_DIR/files/themes/noctalia.ini" \
	"$HOME/.config/copyq/themes/noctalia.ini"

link_file \
	"$MODULE_DIR/files/copyq-commands.ini" \
	"$HOME/.config/copyq/copyq-commands.ini"

link_file \
	"$MODULE_DIR/files/copyq.service" \
	"$HOME/.config/systemd/user/copyq.service"

if command_exists systemctl; then
	systemctl --user daemon-reload
	if command_exists copyq; then
		systemctl --user enable copyq.service
		systemctl --user restart copyq.service || true
	fi
fi

success "CopyQ configured"
