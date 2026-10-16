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

CLI_JSON="$HOME/.config/opencode/cli.json"
TEMPLATE_CLI="$MODULE_DIR/files/cli.json"

if [[ ! -f "$CLI_JSON" ]]; then
	cp "$TEMPLATE_CLI" "$CLI_JSON"
	success "Created ~/.config/opencode/cli.json from template"
else
	if command_exists jq; then
		tmp_file="$(mktemp "${CLI_JSON}.tmp.XXXXXX")"
		jq '.theme = {name: "matugen"}' "$CLI_JSON" > "$tmp_file"
		if ! cmp -s "$CLI_JSON" "$tmp_file"; then
			cat "$tmp_file" > "$CLI_JSON"
			success "Updated ~/.config/opencode/cli.json with matugen theme"
		fi
		rm -f "$tmp_file"
	fi
fi

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
