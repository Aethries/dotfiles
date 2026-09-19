#!/usr/bin/env python3
"""Kanata Mode HUD & On-Screen Layer Indicator Overlay

Displays a small, sleek semi-transparent pill at bottom-center of the screen
indicating the currently active Kanata layer. Automatically hides in NORMAL mode.
Input events pass through transparently without stealing focus.
"""

import os
import re
import subprocess
import sys
import threading
import time

import cairo
import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
from gi.repository import Gdk, GLib, Gtk, GtkLayerShell

RUNTIME_DIR = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
MODE_FILE = os.path.join(RUNTIME_DIR, "kanata-mode")

LAYERS = {
    "navigate": {
        "badge": "🧭 NAVIGATE",
        "desc": "h/j/k/l · w/e · v:Visual · m/M:Mouse · Esc:Exit",
        "badge_color": "#89b4fa",
    },
    "visual": {
        "badge": "👁️ VISUAL",
        "desc": "w/e/b:Word · h/j/k/l:Char · y/x:Yank/Cut · Esc:Exit",
        "badge_color": "#f9e2af",
    },
    "super": {
        "badge": "⚡ SUPER",
        "desc": "a:Super · s:Shift · d:Ctrl · f:Alt · Esc:Exit",
        "badge_color": "#cba6f7",
    },
    "chromium": {
        "badge": "🌐 CHROMIUM",
        "desc": "t:New · x:Close · j/k:Scroll · Esc:Exit",
        "badge_color": "#a6e3a1",
    },
    "terminals": {
        "badge": "📟 TERMINALS",
        "desc": "h/l:Panes · s:Session · x:Close · Esc:Exit",
        "badge_color": "#fab387",
    },
    "niri": {
        "badge": "🪟 NIRI",
        "desc": "h/l:Col · j/k:Ws · 1-9:Jump · c/p/s/r/d/t · Esc:Exit",
        "badge_color": "#94e2d5",
    },
    "ctrl_locked": {
        "badge": "🔒 CTRL LOCKED",
        "desc": "Sticky Ctrl Active · Esc:Unlock",
        "badge_color": "#f38ba8",
    },
    "super_locked": {
        "badge": "🔒 SUPER LOCKED",
        "desc": "Sticky Super Active · Esc:Unlock",
        "badge_color": "#f38ba8",
    },
    "alt_locked": {
        "badge": "🔒 ALT LOCKED",
        "desc": "Sticky Alt Active · Esc:Unlock",
        "badge_color": "#f38ba8",
    },
    "shift_locked": {
        "badge": "🔒 SHIFT LOCKED",
        "desc": "Sticky Shift Active · Esc:Unlock",
        "badge_color": "#f38ba8",
    },
    "nav_slk": {
        "badge": "🧭 NAV (LOCKED)",
        "desc": "Navigation in locked mode · Esc:Back",
        "badge_color": "#f38ba8",
    },
    "nav_clk": {
        "badge": "🧭 NAV (LOCKED)",
        "desc": "Navigation in locked mode · Esc:Back",
        "badge_color": "#f38ba8",
    },
    "bypass": {
        "badge": "⚠️ BYPASS",
        "desc": "Hardware 1:1 Passthrough · Dual Shift to toggle",
        "badge_color": "#fab387",
    },
}

SHORT_MODES = {
    "normal": "NORMAL",
    "navigate": "NAV",
    "visual": "VIS",
    "chromium": "CHROM",
    "terminals": "TERM",
    "niri": "NIRI",
    "super": "SUPER",
    "ctrl_locked": "C-LOCK",
    "super_locked": "M-LOCK",
    "alt_locked": "A-LOCK",
    "shift_locked": "S-LOCK",
    "nav_slk": "NAV-LK",
    "nav_clk": "NAV-LK",
    "bypass": "BYPASS",
}

CSS = b"""
window {
    background: transparent;
}
#hud-container {
    background-color: rgba(24, 24, 37, 0.88);
    border: 1px solid rgba(255, 255, 255, 0.14);
    border-radius: 18px;
    box-shadow: 0 4px 14px rgba(0, 0, 0, 0.4);
}
#hud-badge {
    font-family: 'JetBrainsMono NF', monospace;
    font-size: 13px;
    font-weight: 800;
}
#hud-sep {
    color: rgba(255, 255, 255, 0.3);
    font-size: 13px;
    font-weight: bold;
}
#hud-desc {
    font-family: 'JetBrainsMono NF', monospace;
    font-size: 12px;
    font-weight: 500;
    color: #cdd6f4;
}
"""


class KanataHud:
    def __init__(self):
        self.win = Gtk.Window()
        GtkLayerShell.init_for_window(self.win)
        GtkLayerShell.set_layer(self.win, GtkLayerShell.Layer.OVERLAY)
        GtkLayerShell.set_anchor(self.win, GtkLayerShell.Edge.BOTTOM, True)
        GtkLayerShell.set_margin(self.win, GtkLayerShell.Edge.BOTTOM, 36)
        GtkLayerShell.set_keyboard_mode(self.win, GtkLayerShell.KeyboardMode.NONE)

        self.box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        self.box.set_name("hud-container")
        self.box.set_margin_start(16)
        self.box.set_margin_end(16)
        self.box.set_margin_top(8)
        self.box.set_margin_bottom(8)

        self.lbl_badge = Gtk.Label()
        self.lbl_badge.set_name("hud-badge")

        self.lbl_sep = Gtk.Label(label="·")
        self.lbl_sep.set_name("hud-sep")

        self.lbl_desc = Gtk.Label()
        self.lbl_desc.set_name("hud-desc")

        self.box.pack_start(self.lbl_badge, False, False, 0)
        self.box.pack_start(self.lbl_sep, False, False, 0)
        self.box.pack_start(self.lbl_desc, False, False, 0)
        self.win.add(self.box)

        # Style provider
        provider = Gtk.CssProvider()
        provider.load_from_data(CSS)
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )

        self.win.realize()
        self._apply_clickthrough()

        # Write initial state
        self._update_mode_file("NORMAL")

    def _apply_clickthrough(self):
        gdk_win = self.win.get_window()
        if gdk_win:
            gdk_win.input_shape_combine_region(cairo.Region(), 0, 0)

    def _update_mode_file(self, mode_str):
        try:
            with open(MODE_FILE, "w") as f:
                f.write(f"{mode_str}\n")
        except OSError:
            pass

    def set_layer(self, layer):
        if layer == "caps_mode":
            # Transient chord layer; do not alter HUD
            return

        if layer == "normal":
            self._update_mode_file("NORMAL")
            self.win.hide()
            return

        info = LAYERS.get(layer)
        if info:
            self._update_mode_file(SHORT_MODES.get(layer, layer.upper()))
            self.lbl_badge.set_text(info["badge"])
            self.lbl_desc.set_text(info["desc"])
            color = info.get("badge_color", "#89b4fa")
            self.lbl_badge.set_markup(f'<span foreground="{color}">{info["badge"]}</span>')
            self.win.show_all()
            self._apply_clickthrough()
        else:
            short = layer.upper()
            self._update_mode_file(short)
            self.lbl_badge.set_markup(f'<span foreground="#89b4fa">⚡ {short}</span>')
            self.lbl_desc.set_text("Custom Layer Active")
            self.win.show_all()
            self._apply_clickthrough()


def stream_journal(hud):
    regex = re.compile(r"deflayer\s+([a-zA-Z0-9_]+)")
    while True:
        try:
            proc = subprocess.Popen(
                ["journalctl", "-u", "kanata-internal", "-f", "-n", "0", "-o", "cat"],
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                text=True,
                bufsize=1,
            )
            for line in proc.stdout:
                m = regex.search(line)
                if m:
                    layer = m.group(1)
                    GLib.idle_add(hud.set_layer, layer)
            proc.wait()
        except Exception:
            pass
        time.sleep(1)


def main():
    os.makedirs(RUNTIME_DIR, exist_ok=True)
    hud = KanataHud()

    thread = threading.Thread(target=stream_journal, args=(hud,), daemon=True)
    thread.start()

    Gtk.main()


if __name__ == "__main__":
    main()
