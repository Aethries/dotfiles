-- ==============================================================================
-- Unified Keymaps Loader
-- Populates keybindings from keymaps.manifest
-- Conflict-free with Zellij (Alt-based) and Niri (Mod-based)
-- ==============================================================================

local manifest = require("keymaps.manifest")
local actions = require("config.actions")
local keymap = vim.keymap.set
local default_opts = { noremap = true, silent = true }

for _, entry in ipairs(manifest.entries) do
  local opts = vim.tbl_extend("force", default_opts, { desc = entry.desc })
  local rhs = nil

  if vim.g.vscode then
    if entry.vscode then
      rhs = function()
        actions.execute(entry)
      end
    elseif type(entry.native) == "string" then
      rhs = entry.native
    elseif type(entry.native) == "function" then
      rhs = entry.native
    end
  else
    if entry.action == "terminal.toggle" or entry.action == "ai.toggle_agent" then
      rhs = actions.toggle_terminal
    elseif type(entry.native) == "string" then
      rhs = entry.native
    elseif type(entry.native) == "function" then
      rhs = entry.native
    end
  end

  if rhs then
    keymap(entry.modes, entry.key, rhs, opts)
  end
end

-- Native terminal mode escape & split navigation
if not vim.g.vscode then
  keymap("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
  keymap("t", "jk", "<C-\\><C-n>", { desc = "Exit terminal mode" })
  keymap("t", "<C-h>", "<C-\\><C-n><C-w>h", { desc = "Move to left window" })
  keymap("t", "<C-j>", "<C-\\><C-n><C-w>j", { desc = "Move to bottom window" })
  keymap("t", "<C-k>", "<C-\\><C-n><C-w>k", { desc = "Move to top window" })
  keymap("t", "<C-l>", "<C-\\><C-n><C-w>l", { desc = "Move to right window" })
end
