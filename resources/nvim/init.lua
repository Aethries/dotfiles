-- ==============================================================================
-- Neovim Base Configuration
-- Modular, fast, clean baseline powered by lazy.nvim
-- Unified for Neovim Terminal, Neovide, and Antigravity IDE
-- ==============================================================================

-- Bytecode cache for sub-50ms startup
if vim.loader then
  vim.loader.enable()
end

-- 1. General options & settings (system clipboard, numbers, indents)
require("config.options")

-- 2. Autocmds (highlight on yank, reload, bigfile protection)
require("config.autocmds")

-- 3. Native Neovim / Neovide setup
require("config.keymaps")
require("config.lazy")

local ok, matugen = pcall(require, 'matugen')
if ok then matugen.setup() end
