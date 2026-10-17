#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Configuring Herdr workspace manager"

mkdir -p "$HOME/.config/herdr"

link_file \
	"$MODULE_DIR/files/config.toml" \
	"$HOME/.config/herdr/config.toml"

# Install or sync upstream Herdr agent skill dynamically
if command_exists npx; then
	log "Syncing Herdr agent skill via npx skills"
	npx -y skills add herdrdev/herdr --skill herdr -y || warn "Could not install herdr skill via npx skills"
fi

success "Herdr configured"

