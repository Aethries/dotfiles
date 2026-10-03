-- ==============================================================================
-- Neovim Modern Configuration (Lazy.nvim + Mason LSP + Noctalia Theme Sync)
-- ==============================================================================

-- 1. Core Options & Leader Key
require("config.options")

-- 2. General Keymaps
require("config.keymaps")

-- 3. Plugin Manager (Lazy.nvim)
require("config.lazy")

-- 4. Noctalia Matugen Dynamic Theme Integration
pcall(function()
  require("matugen").setup()
end)
