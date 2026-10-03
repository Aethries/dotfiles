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

# Initialize Noctalia Theme extension folder for VS Code if not exists
NOCTALIA_EXT_DIR="$HOME/.vscode/extensions/noctalia.noctaliatheme-0.0.5"
if [[ ! -d "$NOCTALIA_EXT_DIR" ]]; then
	mkdir -p "$NOCTALIA_EXT_DIR/themes"
	cat << 'EOF' > "$NOCTALIA_EXT_DIR/package.json"
{
  "name": "noctaliatheme",
  "displayName": "NoctaliaTheme",
  "description": "Noctalia Matugen theme for VS Code",
  "version": "0.0.5",
  "publisher": "Noctalia",
  "engines": { "vscode": "^1.106.1" },
  "categories": ["Themes"],
  "contributes": {
    "themes": [
      {
        "label": "NoctaliaTheme",
        "uiTheme": "vs-dark",
        "path": "./themes/NoctaliaTheme-color-theme.json",
        "_watch": true
      }
    ]
  }
}
EOF
fi

# Install extensions independently via code CLI
if command_exists code && [[ -f "$MODULE_DIR/files/extensions.txt" ]]; then
	log "Verifying VS Code extensions from marketplace"
	installed_exts="$(code --list-extensions 2>/dev/null || true)"
	while read -r ext; do
		[[ -z "$ext" || "$ext" =~ ^# ]] && continue
		if ! echo "$installed_exts" | grep -Fqi "$ext"; then
			log "Installing extension: $ext"
			code --install-extension "$ext" >/dev/null 2>&1 || true
		fi
	done < "$MODULE_DIR/files/extensions.txt"
fi

success "VS Code configured"
