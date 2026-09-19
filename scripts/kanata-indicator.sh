#!/usr/bin/env bash
# ==============================================================================
# Kanata Mode Indicator & On-Screen Overlay Daemon
# ==============================================================================
set -euo pipefail

RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
MODE_FILE="$RUNTIME_DIR/kanata-mode"
mkdir -p "$RUNTIME_DIR"

# Initialize default state
echo "NORMAL" > "$MODE_FILE"

send_osd() {
    local title="$1"
    local desc="$2"
    local timeout="$3"
    notify-send -u low -t "$timeout" \
        -h string:x-canonical-private-synchronous:kanata_mode \
        -a "Kanata" "$title" "$desc" || true
}

# Stream Kanata layer change events from journald
stdbuf -oL journalctl -u kanata-internal -f -n 0 -o cat | while IFS= read -r line; do
    if [[ "$line" =~ deflayer[[:space:]]+([a-zA-Z0-9_]+) ]]; then
        layer="${BASH_REMATCH[1]}"
        case "$layer" in
            normal)
                echo "NORMAL" > "$MODE_FILE"
                send_osd "⌨️ NORMAL" "Default Typing Mode" 500
                ;;
            navigate)
                echo "NAV" > "$MODE_FILE"
                send_osd "🧭 NAVIGATE" "h/j/k/l · w/e · v:Visual · Tab · 1:Niri · 2:Chrom · 3:Term · Esc:Exit" 2000
                ;;
            visual)
                echo "VIS" > "$MODE_FILE"
                send_osd "👁️ VISUAL" "w/e/b:Word · h/j/k/l:Char/Line · y:Copy · x/c:Cut · v/Esc:Exit" 2000
                ;;
            chromium)
                echo "CHROM" > "$MODE_FILE"
                send_osd "🌐 CHROMIUM" "t/S-t:Tab · r:Reload · x:Close · m:Mute · h/l:Tabs · j/k:Scroll · Esc:Exit" 2000
                ;;
            terminals)
                echo "TERM" > "$MODE_FILE"
                send_osd "📟 TERMINALS" "h/l:Panes · j/k:Arrows · s:Session · x:Close · w:Win · Esc:Exit" 2000
                ;;
            niri)
                echo "NIRI" > "$MODE_FILE"
                send_osd "🪟 NIRI" "h/l:Col · j/k:Ws · 1-9:Jump · c/p/s/r/d/t:Actions · Esc:Exit" 2000
                ;;
            super)
                echo "SUPER" > "$MODE_FILE"
                send_osd "⚡ SUPER" "a:Super · s:Shift · d:Ctrl · f:Alt · Esc/RShift:Back" 2000
                ;;
            ctrl_locked)
                echo "C-LOCK" > "$MODE_FILE"
                send_osd "🔒 CTRL LOCKED" "Sticky Ctrl Active · Esc:Unlock" 2000
                ;;
            super_locked)
                echo "M-LOCK" > "$MODE_FILE"
                send_osd "🔒 SUPER LOCKED" "Sticky Super Active · Esc:Unlock" 2000
                ;;
            alt_locked)
                echo "A-LOCK" > "$MODE_FILE"
                send_osd "🔒 ALT LOCKED" "Sticky Alt Active · Esc:Unlock" 2000
                ;;
            shift_locked)
                echo "S-LOCK" > "$MODE_FILE"
                send_osd "🔒 SHIFT LOCKED" "Sticky Shift Active · Esc:Unlock" 2000
                ;;
            nav_slk|nav_clk)
                echo "NAV-LK" > "$MODE_FILE"
                send_osd "🧭 NAVIGATE (LOCKED)" "Navigation in locked mode · Esc/i:Back to lock" 2000
                ;;
            bypass)
                echo "BYPASS" > "$MODE_FILE"
                send_osd "⚠️ BYPASS" "Hardware 1:1 Passthrough · Dual Shift to toggle" 2000
                ;;
            caps_mode)
                # Transient chord layer for CapsLock; ignore
                ;;
            *)
                echo "$layer" > "$MODE_FILE"
                ;;
        esac
    fi
done
