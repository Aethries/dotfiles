#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Configuring Quickshell (end4-pC Material 3 shell)"

QUICKSHELL_DIR="$HOME/.config/quickshell"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell"
VENV="$STATE_DIR/.venv"

mkdir -p \
	"$QUICKSHELL_DIR" \
	"$STATE_DIR" \
	"$HOME/.config/illogical-impulse" \
	"$HOME/Pictures/Wallpapers"

link_dir \
	"$MODULE_DIR/files/end4-pC" \
	"$QUICKSHELL_DIR/end4-pC"

chmod +x "$MODULE_DIR/files/end4-pC/scripts/colors/"*.sh 2>/dev/null || true

# Python runtime used by material color generation and desktop widgets.
if [[ ! -x "$VENV/bin/python" ]]; then
	log "Creating Quickshell Python virtualenv"
	if ! python3 -m venv --system-site-packages "$VENV"; then
		warn "Could not create Python virtualenv at $VENV; color generation may be limited"
	fi
fi

if [[ -x "$VENV/bin/python" ]]; then
	if command_exists uv; then
		uv pip install --python "$VENV/bin/python" -q \
			-r "$MODULE_DIR/files/requirements.txt" ||
			warn "Could not install core Quickshell Python dependencies"
		uv pip install --python "$VENV/bin/python" -q kde-material-you-colors ||
			warn "Could not install kde-material-you-colors (Qt app theming will be skipped)"
	else
		"$VENV/bin/pip" install -q -r "$MODULE_DIR/files/requirements.txt" ||
			warn "Could not install core Quickshell Python dependencies"
		"$VENV/bin/pip" install -q kde-material-you-colors ||
			warn "Could not install kde-material-you-colors (Qt app theming will be skipped)"
	fi
fi

success "Quickshell configured"
