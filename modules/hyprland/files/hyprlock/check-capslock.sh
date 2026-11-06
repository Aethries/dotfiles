#!/usr/bin/env bash
# Shows a Caps Lock warning on the Hyprlock surface.
set -euo pipefail

hyprctl devices -j 2>/dev/null |
	jq -r '.keyboards[] | select(.main == true) | if .capsLock then "Caps Lock ON" else "" end' 2>/dev/null || true
