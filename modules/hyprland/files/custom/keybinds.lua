-- =============================================================================
-- Personal Keybinds
-- Preserves the familiar keyboard workflow and wires it directly into the
-- end4-pC Material 3 widgets.
-- Loaded after hyprland/keybinds.lua, so overrides are applied here.
-- =============================================================================

-- Replace an existing default bind without leaving both handlers active.
local function override(keys, dispatcher, opts)
    hl.unbind(keys)
    hl.bind(keys, dispatcher, opts)
end

-- -----------------------------------------------------------------------------
-- Applications
-- -----------------------------------------------------------------------------
override("SUPER + Return", hl.dsp.exec_cmd(terminal), { description = "App: Terminal (Ghostty)" })
override("SUPER + A", hl.dsp.exec_cmd("ghostty -e herdr"), { description = "App: Herdr" })
override("SUPER + B", hl.dsp.exec_cmd(browser), { description = "App: Browser (Chrome)" })
override("SUPER + E", hl.dsp.exec_cmd("nautilus --new-window"), { description = "App: Files (Nautilus)" })

-- -----------------------------------------------------------------------------
-- Material 3 shell widgets (Quickshell / end4-pC)
-- -----------------------------------------------------------------------------
hl.bind("SUPER + Space", hl.dsp.global("quickshell:searchToggleRelease"),
    { description = "Shell: Launcher" })
override("SUPER + D", hl.dsp.global("quickshell:searchToggleRelease"),
    { description = "Shell: Launcher" })
override("SUPER + V", hl.dsp.global("quickshell:overviewClipboardToggle"),
    { description = "Shell: Clipboard" })
override("SUPER + Tab", hl.dsp.global("quickshell:overviewWorkspacesToggle"),
    { description = "Shell: Overview" })
override("SUPER + O", hl.dsp.global("quickshell:overviewWorkspacesToggle"),
    { description = "Shell: Overview" })
hl.bind("SUPER + Comma", hl.dsp.global("quickshell:settingsToggle"),
    { description = "Shell: Settings" })
hl.bind("SUPER + BackSpace", hl.dsp.global("quickshell:lock"),
    { description = "Session: Lock" })

-- Never quit the compositor by accident while working remotely.
hl.bind("SUPER + Escape", hl.dsp.no_op(), { description = "Session: Disabled" })

-- -----------------------------------------------------------------------------
-- Screenshots, OCR and screen recording
-- -----------------------------------------------------------------------------
override("Print", hl.dsp.global("quickshell:regionScreenshot"),
    { description = "Screenshot: Region" })
override("SUPER + S", hl.dsp.global("quickshell:regionScreenshot"),
    { description = "Screenshot: Region" })
hl.bind("SUPER + R", hl.dsp.global("quickshell:regionRecord"),
    { locked = true, description = "Capture: Record region" })

-- -----------------------------------------------------------------------------
-- Wallpaper & theme
-- -----------------------------------------------------------------------------
override("CTRL + SUPER + T", hl.dsp.global("quickshell:wallpaperSelectorToggle"),
    { description = "Shell: Change wallpaper" })
override("CTRL + SUPER + ALT + T", hl.dsp.global("quickshell:wallpaperSelectorRandom"),
    { description = "Shell: Random wallpaper" })

-- Keep-awake toggle (systemd inhibitor fallback through coffee)
hl.bind("SUPER + SHIFT + I", hl.dsp.exec_cmd("coffee toggle"),
    { description = "System: Toggle keep-awake" })

-- -----------------------------------------------------------------------------
-- Workspace navigation (J / K)
-- -----------------------------------------------------------------------------
override("SUPER + J", hl.dsp.focus({ workspace = "m+1" }),
    { description = "Workspace: Next" })
override("SUPER + K", hl.dsp.focus({ workspace = "m-1" }),
    { description = "Workspace: Previous" })
hl.bind("SUPER + SHIFT + J", hl.dsp.window.move({ workspace = "m+1" }),
    { description = "Window: Move to next workspace" })
hl.bind("SUPER + SHIFT + K", hl.dsp.window.move({ workspace = "m-1" }),
    { description = "Window: Move to previous workspace" })

-- -----------------------------------------------------------------------------
-- Window state & movement
-- -----------------------------------------------------------------------------
hl.bind("SUPER + SHIFT + Space", hl.dsp.window.float({ action = "toggle" }),
    { description = "Window: Toggle floating" })

hl.bind("SUPER + SHIFT + H", hl.dsp.window.move({ direction = "l" }),
    { description = "Window: Move left" })
hl.bind("SUPER + SHIFT + L", hl.dsp.window.move({ direction = "r" }),
    { description = "Window: Move right" })

-- Quick window switcher (overview)
hl.bind("ALT + Tab", hl.dsp.global("quickshell:overviewWorkspacesToggle"),
    { description = "Shell: Window switcher" })
