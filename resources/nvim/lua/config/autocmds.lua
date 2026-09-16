-- ==============================================================================
-- Neovim Autocmds
-- Essential automation for ergonomics, performance, and big-file protection
-- ==============================================================================

local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

local core_group = augroup("DotfilesCoreAutocmds", { clear = true })

-- 1. Highlight text on yank
autocmd("TextYankPost", {
  group = core_group,
  desc = "Highlight copied text",
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 })
  end,
})

-- 2. Auto-reload buffer when modified outside
autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  group = core_group,
  desc = "Check if file changed on disk",
  callback = function()
    if vim.fn.getcmdwintype() == "" then
      vim.cmd("checktime")
    end
  end,
})

-- 3. Equalize window splits on window resize
autocmd("VimResized", {
  group = core_group,
  desc = "Keep splits balanced on resize",
  command = "tabdo wincmd =",
})

-- 4. Close auxiliary windows with 'q'
autocmd("FileType", {
  group = core_group,
  pattern = {
    "help",
    "lspinfo",
    "man",
    "notify",
    "qf",
    "query",
    "checkhealth",
  },
  desc = "Close helper windows with q",
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = event.buf, silent = true, desc = "Close window" })
  end,
})

-- 5. Big-file performance guard (R11 budget)
autocmd("BufReadPre", {
  group = core_group,
  desc = "Disable expensive features for large files (>1.5MB)",
  callback = function(args)
    local max_size = 1.5 * 1024 * 1024 -- 1.5 MB
    local ok, stat = pcall(vim.uv.fs_stat, args.file)
    if ok and stat and stat.size > max_size then
      vim.b.bigfile = true
      vim.cmd("syntax off")
      vim.opt_local.foldmethod = "manual"
      vim.opt_local.undolevels = -1
      vim.opt_local.swapfile = false
      vim.notify("Big file detected (" .. math.floor(stat.size / 1024) .. " KB). Syntax/LSP disabled.", vim.log.levels.WARN)
    end
  end,
})
