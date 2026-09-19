--!nonstrict

local PANEL_ID = "blackbartblues/keymap:panel"

local glyph = "keyboard"
local showLabel = true

local function readConfig()
  glyph = noctalia.getConfig("glyph") or "keyboard"
  showLabel = noctalia.getConfig("show_label") ~= false
end

local function render()
  local mode = "NORMAL"
  local uid = 1000
  local path = "/run/user/" .. tostring(uid) .. "/kanata-mode"
  local content = noctalia.readFile(path)
  if content and content ~= "" then
    mode = content:gsub("%s+", "")
  end

  barWidget.setGlyph(glyph)
  barWidget.setText(mode)
  barWidget.setTooltip("Kanata Mode: " .. mode .. " (Click to toggle keymap panel)")
end

function update()
  noctalia.setUpdateInterval(250)
  readConfig()
  render()
end

function onConfigChanged()
  readConfig()
  render()
end

function onClick()
  noctalia.togglePanel(PANEL_ID)
end
