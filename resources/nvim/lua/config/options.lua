-- ==============================================================================
-- Neovim Options
-- ==============================================================================

local opt = vim.opt

-- Leader Keys (<Space>)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ------------------------------------------------------------------------------
-- System Clipboard Integration
-- Syncs unnamed and unnamedplus register directly with Wayland / X11 clipboard
-- ------------------------------------------------------------------------------
opt.clipboard = "unnamedplus"

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Tabs & Indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
opt.expandtab = true
opt.smartindent = true
opt.autoindent = true

-- Search behavior
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- Appearance & UI
opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.wrap = false
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.pumheight = 10
opt.showmode = false

-- File persistence & undo history
opt.backup = false
opt.writebackup = false
opt.swapfile = false
opt.undofile = true
opt.undolevels = 10000

-- Word & Identifier boundary handling (treat '-' as part of full identifier)
opt.iskeyword:append("-")

-- Timing & Responsiveness
opt.updatetime = 200
opt.timeoutlen = 300

-- Window splitting behavior
opt.splitbelow = true
opt.splitright = true

-- Mouse support
opt.mouse = "a"

-- Completion options
opt.completeopt = { "menu", "menuone", "noselect" }

-- ------------------------------------------------------------------------------
-- Neovide GUI Settings
-- ------------------------------------------------------------------------------
if vim.g.neovide then
  vim.o.guifont = "JetBrainsMono Nerd Font:h12"
  vim.g.neovide_opacity = 0.95
  vim.g.neovide_floating_blur_amount_x = 2.0
  vim.g.neovide_floating_blur_amount_y = 2.0
  vim.g.neovide_cursor_animation_length = 0.08
  vim.g.neovide_cursor_trail_size = 0.4
  vim.g.neovide_cursor_antialiasing = true
  vim.g.neovide_scroll_animation_length = 0.2
  vim.g.neovide_hide_mouse_when_typing = true
  vim.g.neovide_remember_window_size = true
end
