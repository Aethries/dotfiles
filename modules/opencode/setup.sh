#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Configuring OpenCode"

mkdir -p "$HOME/.config/opencode"
mkdir -p "$HOME/.config/opencode/themes"

link_file \
	"$MODULE_DIR/files/opencode.json" \
	"$HOME/.config/opencode/opencode.json"

link_file \
	"$MODULE_DIR/files/matugen-template.json" \
	"$HOME/.config/opencode/matugen-template.json"

if ! command_exists opencode; then
	if command_exists pacman; then
		log "Installing opencode via pacman"
		sudo pacman -S --noconfirm --needed opencode || warn "Failed to install opencode via pacman"
	elif command_exists mise; then
		log "Installing @opencode/cli via mise / npm"
		mise exec -- npm install -g @opencode/cli || warn "Failed to install @opencode/cli via mise"
		mise reshim 2>/dev/null || true
	elif command_exists npm; then
		log "Installing @opencode/cli via npm"
		npm install -g @opencode/cli || warn "Failed to install @opencode/cli via npm"
	fi
fi

success "OpenCode configured"
