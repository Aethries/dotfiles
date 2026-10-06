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

# Deploy default hooks if not already present
if [[ ! -f "$HOME/.codex/hooks.json" && -f "$MODULE_DIR/files/hooks.json" ]]; then
	cp "$MODULE_DIR/files/hooks.json" "$HOME/.codex/hooks.json"
	success "Installed default Codex hooks (JEV preflight)"
fi

# Ensure codex CLI is installed
if ! command_exists codex; then
	log "Installing @openai/codex CLI via mise / npm"
	if command_exists mise; then
		mise exec -- npm install -g @openai/codex || warn "Failed to install @openai/codex via mise"
		mise reshim 2>/dev/null || true
	elif command_exists npm; then
		npm install -g @openai/codex || warn "Failed to install @openai/codex via npm"
	fi
fi

success "Codex configured"
