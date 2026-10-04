#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Setting up Clipboard Manager (Clipse with Noctalia Theme)"

mkdir -p "$HOME/.config/clipse"
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.config/systemd/user"

# Symlink Clipse binary from go bin if installed via go
if [[ -f "$HOME/go/bin/clipse" && ! -f "$HOME/.local/bin/clipse" ]]; then
	ln -sf "$HOME/go/bin/clipse" "$HOME/.local/bin/clipse"
fi

link_file \
	"$MODULE_DIR/files/config.json" \
	"$HOME/.config/clipse/config.json"

link_file \
	"$MODULE_DIR/files/custom_theme.json" \
	"$HOME/.config/clipse/custom_theme.json"

link_file \
	"$MODULE_DIR/files/clip-picker" \
	"$HOME/.local/bin/clip-picker"

chmod +x "$MODULE_DIR/files/clip-picker"
chmod +x "$HOME/.local/bin/clip-picker" 2>/dev/null || true

link_file \
	"$MODULE_DIR/files/clipse.service" \
	"$HOME/.config/systemd/user/clipse.service"

# Clean up deprecated copyq and cliphist services/files
if command_exists systemctl; then
	systemctl --user stop copyq.service 2>/dev/null || true
	systemctl --user disable copyq.service 2>/dev/null || true
	systemctl --user stop cliphist.service 2>/dev/null || true
	systemctl --user disable cliphist.service 2>/dev/null || true
fi
rm -f "$HOME/.config/systemd/user/copyq.service"
rm -f "$HOME/.config/systemd/user/cliphist.service"
rm -f "$HOME/.local/bin/copyq-toggle"
rm -f "$HOME/.local/bin/cliphist-picker"
rm -rf "$HOME/.config/copyq"


if command_exists systemctl; then
	systemctl --user daemon-reload
	if command_exists clipse || [[ -x "$HOME/.local/bin/clipse" || -x "$HOME/go/bin/clipse" ]]; then
		systemctl --user enable clipse.service
		systemctl --user restart clipse.service || true
	fi
fi

success "Clipse Clipboard Manager configured"
