#!/usr/bin/env bash
# ==============================================================================
# Kanata Mode Indicator & On-Screen Overlay Daemon
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
HUD_SCRIPT="$SCRIPT_DIR/kanata-hud.py"

# Prefer system-installed or nix-wrapped binary if available
if command -v kanata-hud >/dev/null 2>&1; then
    exec kanata-hud
fi

exec nix-shell -p wrapGAppsHook3 gobject-introspection gtk3 gtk-layer-shell python3Packages.pygobject3 python3Packages.pycairo --run "python3 $HUD_SCRIPT"

