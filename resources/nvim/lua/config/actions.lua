-- ==============================================================================
-- Actions Adapter: Host-Aware Semantic Action Dispatcher
-- Bridges Native Neovim/Neovide and Antigravity IDE (VS Code Neovim)
-- ==============================================================================

local M = {}

-- State for native terminal toggle
local term_buf = nil
local term_win = nil

function M.toggle_terminal()
  if vim.g.vscode then
    require("vscode").action("workbench.action.terminal.toggleTerminal")
    return
  end

  if term_win and vim.api.nvim_win_is_valid(term_win) then
    vim.api.nvim_win_hide(term_win)
    term_win = nil
    return
  end

  if not term_buf or not vim.api.nvim_buf_is_valid(term_buf) then
    term_buf = vim.api.nvim_create_buf(false, true)
  end

  vim.cmd("botright 14split")
  term_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(term_win, term_buf)

  if vim.bo[term_buf].buftype ~= "terminal" then
    vim.fn.termopen(os.getenv("SHELL") or "bash")
  end
  vim.cmd("startinsert")
end

function M.close_other_buffers()
  if vim.g.vscode then
    require("vscode").action("workbench.action.closeOtherEditors")
    return
  end

  local current = vim.api.nvim_get_current_buf()
  local closed = 0
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buf ~= current and vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted then
      local ok = pcall(vim.api.nvim_buf_delete, buf, { force = false })
      if ok then closed = closed + 1 end
    end
  end
  vim.notify("Closed " .. closed .. " other buffer(s)", vim.log.levels.INFO)
end

function M.execute(entry)
  if vim.g.vscode then
    if entry.vscode then
      require("vscode").action(entry.vscode)
    elseif type(entry.native) == "function" then
      entry.native()
    end
  else
    if entry.action == "terminal.toggle" or entry.action == "ai.toggle_agent" then
      M.toggle_terminal()
    elseif entry.action == "buffer.close_others" then
      M.close_other_buffers()
    elseif type(entry.native) == "function" then
      entry.native()
    elseif type(entry.native) == "string" and entry.native:sub(1, 5) == "<cmd>" then
      local cmd = entry.native:sub(6, -5)
      vim.cmd(cmd)
    end
  end
end

return M
