#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Configuring Antigravity CLI"

# ponytail: Antigravity CLI only; add IDE config if Antigravity IDE is re-added.
# Link MCP config for Antigravity CLI and Gemini config
link_file \
	"$MODULE_DIR/files/mcp_config.json" \
	"$HOME/.gemini/antigravity-cli/mcp_config.json"

link_file \
	"$MODULE_DIR/files/mcp_config.json" \
	"$HOME/.gemini/config/mcp_config.json"

# Clean up obsolete IDE utilities if present
rm -f "$HOME/.local/bin/sync-antigravity-extensions" "$HOME/.local/bin/sync-antigravity"

success "Antigravity CLI configured"
