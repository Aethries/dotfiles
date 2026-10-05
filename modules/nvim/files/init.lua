-- ==============================================================================
-- Neovim Modern Configuration (Lazy.nvim + Mason LSP + Noctalia Theme Sync)
-- ==============================================================================

-- 1. Core Options & Leader Key
require("config.options")

-- 2. General Keymaps
require("config.keymaps")

-- 3. Interactive Bilingual Cheatsheet (Command & Keymaps)
pcall(require, "config.cheatsheet")

-- 4. Plugin Manager (Lazy.nvim)
require("config.lazy")

-- 5. Noctalia Matugen Dynamic Theme Integration
pcall(function()
    require("matugen").setup()
end)

-- 6. Neovide GUI Integration (VSCode / WebStorm Modern IDE Aesthetics)
if vim.g.neovide then
    pcall(require, "config.neovide")
end
