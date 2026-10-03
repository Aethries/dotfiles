#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Configuring Antigravity IDE"

# User directories to link:
# - ~/.config/Antigravity IDE/User (Arch Linux AUR package default)
# - ~/.antigravity-ide/User (compatibility)
TARGET_DIRS=(
	"$HOME/.config/Antigravity IDE/User"
	"$HOME/.antigravity-ide/User"
)

for user_dir in "${TARGET_DIRS[@]}"; do
	mkdir -p "$user_dir/snippets"

	link_file \
		"$MODULE_DIR/files/settings.json" \
		"$user_dir/settings.json"

	link_file \
		"$MODULE_DIR/files/keybindings.json" \
		"$user_dir/keybindings.json"

	link_file \
		"$MODULE_DIR/files/snippets/main.code-snippets" \
		"$user_dir/snippets/main.code-snippets"
done

# Link MCP config for Antigravity, Antigravity CLI, and Gemini config
link_file \
	"$MODULE_DIR/files/mcp_config.json" \
	"$HOME/.gemini/antigravity/mcp_config.json"

link_file \
	"$MODULE_DIR/files/mcp_config.json" \
	"$HOME/.gemini/antigravity-cli/mcp_config.json"

link_file \
	"$MODULE_DIR/files/mcp_config.json" \
	"$HOME/.gemini/config/mcp_config.json"

success "Antigravity IDE configured"
