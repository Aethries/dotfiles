#!/usr/bin/env bash

set -euo pipefail

# Screenshot tool using wayfreeze, grim, slurp, satty and wl-copy
# Mode: "area" (default), "full", "window"

MODE="${1:-area}"
SAVE_DIR="${HOME}/Pictures/Screenshots"
mkdir -p "$SAVE_DIR"

TIMESTAMP="$(date +'%Y-%m-%d_%H-%M-%S')"
OUTPUT_FILE="${SAVE_DIR}/Screenshot_${TIMESTAMP}.png"
TEMP_FILE="$(mktemp --suffix=.png)"
trap 'rm -f "$TEMP_FILE"' EXIT

# Detect wayfreeze for screen freeze
WAYFREEZE_CMD=""
if command -v wayfreeze >/dev/null 2>&1; then
    WAYFREEZE_CMD="wayfreeze"
elif [ -x "$HOME/.local/bin/wayfreeze" ]; then
    WAYFREEZE_CMD="$HOME/.local/bin/wayfreeze"
fi

if [ "$MODE" = "full" ]; then
    # Fullscreen capture
    grim "$TEMP_FILE"
    if [ -s "$TEMP_FILE" ]; then
        satty --filename "$TEMP_FILE" --output-filename "$OUTPUT_FILE" --early-exit --copy-command wl-copy
    fi
else
    # Area or Window selection (with freeze support)
    if [ -n "$WAYFREEZE_CMD" ]; then
        # Freeze screen, select geometry with slurp, capture with grim, then immediately unfreeze
        $WAYFREEZE_CMD --hide-cursor --after-freeze-cmd "
            GEOM=\"\$(slurp 2>/dev/null || true)\"
            if [ -n \"\$GEOM\" ]; then
                grim -g \"\$GEOM\" \"$TEMP_FILE\"
            fi
            pkill -x wayfreeze 2>/dev/null || true
        " 2>/dev/null || true
    else
        # Fallback without freeze
        GEOM="$(slurp 2>/dev/null || true)"
        if [ -n "$GEOM" ]; then
            grim -g "$GEOM" "$TEMP_FILE"
        fi
    fi

    # If an image was captured, open annotation editor
    if [ -s "$TEMP_FILE" ]; then
        satty --filename "$TEMP_FILE" --output-filename "$OUTPUT_FILE" --early-exit --copy-command wl-copy
    fi
fi
