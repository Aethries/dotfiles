-- ==============================================================================
-- Environment Detection & Host Capabilities
-- ==============================================================================

local M = {}

M.is_neovide = vim.g.neovide ~= nil
M.is_headless = #vim.api.nvim_list_uis() == 0
M.has_wayland = os.getenv("WAYLAND_DISPLAY") ~= nil

-- Minimum version verification (Neovim 0.11+)
local v = vim.version()
M.version_ok = v.major > 0 or (v.major == 0 and v.minor >= 11)

return M
