#!/usr/bin/env bash
set -euo pipefail

# Ensure standard user binary locations are available
export PATH="$HOME/.local/bin:$HOME/go/bin:/usr/local/bin:/usr/bin:$PATH"

if ! command -v cliphist >/dev/null 2>&1; then
	if command -v notify-send >/dev/null 2>&1; then
		notify-send -u critical "Clipboard Manager" "cliphist is not installed"
	fi
	exit 1
fi

# Use fzf in terminal, Noctalia dmenu in GUI
if [[ -t 0 ]]; then
	selected="$(cliphist list | fzf --prompt="📋 Clipboard > ")"
else
	selected="$(cliphist list | noctalia dmenu --prompt "📋 Clipboard")"
fi

if [[ -n "${selected:-}" ]]; then
	echo "$selected" | cliphist decode | wl-copy
fi
