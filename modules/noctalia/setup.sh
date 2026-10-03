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

success "Noctalia configured"
