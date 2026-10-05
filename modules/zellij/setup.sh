#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Setting up Zellij terminal multiplexer"

mkdir -p "$HOME/.config/zellij"

chmod +x "$MODULE_DIR/files/scripts/launcher.sh"

link_file \
	"$MODULE_DIR/files/config.kdl" \
	"$HOME/.config/zellij/config.kdl"

link_dir \
	"$MODULE_DIR/files/layouts" \
	"$HOME/.config/zellij/layouts"

link_dir \
	"$MODULE_DIR/files/scripts" \
	"$HOME/.config/zellij/scripts"

link_dir \
	"$MODULE_DIR/files/themes" \
	"$HOME/.config/zellij/themes"

link_dir \
	"$MODULE_DIR/files/plugins" \
	"$HOME/.config/zellij/plugins"

mkdir -p "$HOME/.cache/zellij"
PERM_FILE="$HOME/.cache/zellij/permissions.kdl"
ensure_plugin_perm() {
	local path="$1"
	shift
	if [[ ! -f "$PERM_FILE" ]] || ! grep -Fq -- "\"$path\" {" "$PERM_FILE"; then
		{
			printf '"%s" {\n' "$path"
			printf '    %s\n' "$@"
			printf '}\n'
		} >> "$PERM_FILE"
	fi
}

ensure_plugin_perm "$HOME/.config/zellij/plugins/zjstatus.wasm" \
	ChangeApplicationState ReadApplicationState RunCommands
ensure_plugin_perm "file:$HOME/.config/zellij/plugins/zjstatus.wasm" \
	ChangeApplicationState ReadApplicationState RunCommands

for path in \
	"$HOME/.config/zellij/plugins/vim-zellij-navigator.wasm" \
	"file:$HOME/.config/zellij/plugins/vim-zellij-navigator.wasm" \
	'file:~/.config/zellij/plugins/vim-zellij-navigator.wasm'; do
	ensure_plugin_perm "$path" \
		WriteToStdin ChangeApplicationState ReadApplicationState
done

success "Zellij configured"
