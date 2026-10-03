-- ==============================================================================
-- Neovim Core Options
-- ==============================================================================

vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Tabs & Indentation
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true
opt.autoindent = true

-- Line wrapping
opt.wrap = false

-- Search settings
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false
opt.incsearch = true

-- Appearance & Colors
opt.termguicolors = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.guifont = "JetBrainsMono Nerd Font:h10.5"

-- Clipboard & System integration
opt.clipboard = "unnamedplus"

-- Ensure mise shims, cargo, and user local bin are available in PATH
local paths_to_prepend = {
  vim.fn.expand("~/.local/share/mise/shims"),
  vim.fn.expand("~/.local/bin"),
  vim.fn.expand("~/.cargo/bin"),
  vim.fn.expand("~/go/bin"),
}
for _, p in ipairs(paths_to_prepend) do
  if vim.fn.isdirectory(p) == 1 and not string.find(vim.env.PATH, p, 1, true) then
    vim.env.PATH = p .. ":" .. vim.env.PATH
  end
end

-- Undo & Backup
opt.swapfile = false
opt.backup = false
opt.undofile = true
opt.undodir = vim.fn.stdpath("data") .. "/undo"

-- Behavior
opt.updatetime = 50
opt.timeoutlen = 300
opt.splitright = true
opt.splitbelow = true
opt.mouse = "a"
opt.confirm = true
