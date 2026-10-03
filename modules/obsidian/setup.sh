#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Setting up Obsidian theme sync"

# Discover Obsidian vaults up to 4 levels deep in $HOME
find_vaults() {
	find "$HOME" -maxdepth 4 -name ".obsidian" -type d 2>/dev/null | sort -u
}

vault_count=0
while read -r obsidian_dir; do
	[[ -z "$obsidian_dir" ]] && continue
	((vault_count++))
	snippets_dir="$obsidian_dir/snippets"
	mkdir -p "$snippets_dir"

	link_file \
		"$MODULE_DIR/files/snippets/noctalia.css" \
		"$snippets_dir/noctalia.css"

	appearance_file="$obsidian_dir/appearance.json"
	if [[ ! -f "$appearance_file" ]]; then
		printf '{\n  "enabledCssSnippets": ["noctalia"]\n}\n' > "$appearance_file"
	else
		python3 -c "
import json
with open('$appearance_file', 'r') as f:
    try: data = json.load(f)
    except Exception: data = {}
snippets = data.get('enabledCssSnippets', [])
if 'noctalia' not in snippets:
    snippets.append('noctalia')
    data['enabledCssSnippets'] = snippets
    with open('$appearance_file', 'w') as f:
        json.dump(data, f, indent=2)
" 2>/dev/null || true
	fi
done < <(find_vaults)

if (( vault_count > 0 )); then
	success "Obsidian vaults synced ($vault_count vaults configured)"
else
	log "No active Obsidian vaults found in \$HOME (snippet ready in dotfiles)"
fi
