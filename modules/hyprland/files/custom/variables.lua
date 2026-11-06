-- =============================================================================
-- Personal application overrides
-- Loaded after hyprland/variables.lua, before the keybinds are registered.
-- =============================================================================

-- Quickshell configuration folder (end4-pC, Material 3 Expressive)
hl.env("qsConfig", "end4-pC")

-- Personal application and environment defaults.
terminal = "ghostty"
browser = "google-chrome-stable"
fileManager = "nautilus"
codeEditor = "antigravity"

-- Avoid the launch_first_available fallbacks picking tools we do not install.
textEditor = "ghostty -e nvim"
volumeMixer = "pavucontrol"
taskManager = "ghostty -e btop"
