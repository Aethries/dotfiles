#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Configuring Claude Code"

mkdir -p "$HOME/.claude"

link_file \
	"$MODULE_DIR/files/settings.json" \
	"$HOME/.claude/settings.json"

CLAUDE_JSON="$HOME/.claude.json"
TEMPLATE_CLAUDE="$MODULE_DIR/files/claude.json"

if [[ ! -f "$CLAUDE_JSON" ]]; then
	cp "$TEMPLATE_CLAUDE" "$CLAUDE_JSON"
	chmod 600 "$CLAUDE_JSON"
	success "Created ~/.claude.json from template"
else
	# Merge 9remote mcpServer if missing
	if command_exists jq; then
		tmp_file="$(mktemp "${CLAUDE_JSON}.tmp.XXXXXX")"
		jq -s '
			.[0].mcpServers = (.[0].mcpServers // {}) * (.[1].mcpServers // {})
			| .[0]
		' "$CLAUDE_JSON" "$TEMPLATE_CLAUDE" > "$tmp_file"
		if ! cmp -s "$CLAUDE_JSON" "$tmp_file"; then
			cat "$tmp_file" > "$CLAUDE_JSON"
			chmod 600 "$CLAUDE_JSON"
			success "Updated ~/.claude.json with 9remote MCP configuration"
		fi
		rm -f "$tmp_file"
	fi
fi

if ! command_exists claude; then
	log "Installing @anthropic-ai/claude-code via mise / npm"
	if command_exists mise; then
		mise exec -- npm install -g @anthropic-ai/claude-code || warn "Failed to install claude-code via mise"
		mise reshim 2>/dev/null || true
	elif command_exists npm; then
		npm install -g @anthropic-ai/claude-code || warn "Failed to install claude-code via npm"
	fi
fi

success "Claude Code configured"
