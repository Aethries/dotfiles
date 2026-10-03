#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Configuring VS Code"

TARGET_DIRS=(
	"$HOME/.config/Code/User"
	"$HOME/.config/Code - OSS/User"
)

# User configuration files (settings, keybindings, snippets)
for user_dir in "${TARGET_DIRS[@]}"; do
	mkdir -p "$user_dir/snippets"

	link_file \
		"$MODULE_DIR/files/settings.json" \
		"$user_dir/settings.json"

	link_file \
		"$MODULE_DIR/files/keybindings.json" \
		"$user_dir/keybindings.json"

	if [[ -f "$MODULE_DIR/files/snippets/main.code-snippets" ]]; then
		link_file \
			"$MODULE_DIR/files/snippets/main.code-snippets" \
			"$user_dir/snippets/main.code-snippets"
	fi
done

# Sync extensions from Antigravity IDE
EXTENSION_DIRS=(
	"$HOME/.vscode/extensions"
	"$HOME/.vscode-oss/extensions"
)

SOURCE_EXT_DIR="$HOME/.antigravity-ide/extensions"

if [[ -d "$SOURCE_EXT_DIR" ]]; then
	log "Syncing extensions from Antigravity IDE"
	for ext_target in "${EXTENSION_DIRS[@]}"; do
		mkdir -p "$ext_target"
		for ext_folder in "$SOURCE_EXT_DIR"/*/; do
			[[ -d "$ext_folder" ]] || continue
			ext_name="$(basename "$ext_folder")"
			ln -sfn "$ext_folder" "$ext_target/$ext_name"
		done
	done
	success "Extensions synchronized"
fi

success "VS Code configured"
