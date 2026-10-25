#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Setting up Obsidian theme sync"

# Discover vaults via Obsidian config or standard documents directories
find_vaults() {
	local cfg="$HOME/.config/obsidian/obsidian.json"
	if [[ -f "$cfg" ]] && command_exists jq; then
		jq -r '.vaults[]?.path // empty' "$cfg" 2>/dev/null | while IFS= read -r vpath; do
			[[ -n "$vpath" && -d "$vpath/.obsidian" ]] && echo "$vpath/.obsidian"
		done
	fi
	find "${XDG_DOCUMENTS_DIR:-$HOME/Documents}" "$HOME/Notes" "$HOME/Vault" -maxdepth 3 -name ".obsidian" -type d 2>/dev/null || true
}

vault_count=0
while IFS= read -r obsidian_dir; do
	[[ -z "$obsidian_dir" ]] && continue
	vault_count=$((vault_count + 1))
	snippets_dir="$obsidian_dir/snippets"
	mkdir -p "$snippets_dir"

	link_file \
		"$MODULE_DIR/files/snippets/noctalia.css" \
		"$snippets_dir/noctalia.css"

	appearance_file="$obsidian_dir/appearance.json"
	if [[ ! -f "$appearance_file" ]]; then
		printf '{\n  "enabledCssSnippets": ["noctalia"]\n}\n' > "$appearance_file"
	elif command_exists jq; then
		tmp_file="$(mktemp "${appearance_file}.tmp.XXXXXX")"
		jq '.enabledCssSnippets = ((.enabledCssSnippets // []) + ["noctalia"] | unique)' "$appearance_file" > "$tmp_file" && mv "$tmp_file" "$appearance_file"
	fi
done < <(find_vaults | sort -u)

if (( vault_count > 0 )); then
	success "Obsidian vaults synced ($vault_count vaults configured)"
else
	log "No active Obsidian vaults found in \$HOME (snippet ready in dotfiles)"
fi
