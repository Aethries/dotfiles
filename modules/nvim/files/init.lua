-- ==============================================================================
-- Neovim Base Configuration
-- ==============================================================================

-- Typography for GUI frontends (Neovide, etc.)
vim.opt.guifont = "JetBrainsMono Nerd Font:h10.5"

-- Noctalia Matugen Dynamic Theme Integration
pcall(function()
  require("matugen").setup()
end)

local ok, matugen = pcall(require, 'matugen')
if ok then matugen.setup() end
