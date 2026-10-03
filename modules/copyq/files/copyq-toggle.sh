#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.local/bin:$HOME/go/bin:/usr/local/bin:/usr/bin:$PATH"

if command -v copyq >/dev/null 2>&1; then
	exec copyq toggle
elif [[ -x "$HOME/.local/bin/cliphist-picker" ]]; then
	exec "$HOME/.local/bin/cliphist-picker"
else
	notify-send "Clipboard" "No clipboard manager found" 2>/dev/null || true
fi
