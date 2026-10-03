#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Configuring Codex"

mkdir -p "$HOME/.codex"

mkdir -p "$HOME/.codex/themes"

link_file \
	"$MODULE_DIR/files/config.toml" \
	"$HOME/.codex/config.toml"

if [[ -f "$MODULE_DIR/files/themes/noctalia.tmTheme" ]]; then
	link_file \
		"$MODULE_DIR/files/themes/noctalia.tmTheme" \
		"$HOME/.codex/themes/noctalia.tmTheme"
fi

success "Codex configured"
