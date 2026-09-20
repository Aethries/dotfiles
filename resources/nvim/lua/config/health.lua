-- ==============================================================================
-- Health Check Module for Dotfiles Editor Environment
-- Run with: :checkhealth dotfiles
-- ==============================================================================

local M = {}

function M.check()
  local health = vim.health or require("health")
  local start = health.start or health.report_start
  local ok = health.ok or health.report_ok
  local warn = health.warn or health.report_warn
  local error = health.error or health.report_error

  start("Dotfiles Editor Environment")

  -- 1. Neovim version
  local v = vim.version()
  if v.major > 0 or (v.major == 0 and v.minor >= 11) then
    ok(string.format("Neovim version %d.%d.%d (>= 0.11 required)", v.major, v.minor, v.patch))
  else
    error(string.format("Neovim version %d.%d.%d is too old! Please upgrade to 0.11+", v.major, v.minor, v.patch))
  end

  -- 2. Host runtime
  if vim.g.neovide then
    ok("Running as Neovide GUI client")
  else
    ok("Running as Native Terminal Neovim")
  end

  -- 3. Clipboard tool
  if vim.fn.executable("wl-copy") == 1 then
    ok("Wayland clipboard provider found: wl-copy")
  elseif vim.fn.executable("xclip") == 1 then
    ok("X11 clipboard provider found: xclip")
  else
    warn("No native clipboard tool found. Falling back to internal/OSC 52 clipboard.")
  end

  -- 4. Build tools for Treesitter
  if vim.fn.executable("gcc") == 1 or vim.fn.executable("clang") == 1 then
    ok("C compiler available for Treesitter parsers")
  else
    warn("No C compiler (gcc/clang) found. Treesitter pre-compiled parsers needed.")
  end

  -- 5. Node.js for Antigravity & LSP
  if vim.fn.executable("node") == 1 then
    ok("Node.js runtime found: " .. vim.fn.system("node --version"):gsub("%s+", ""))
  else
    warn("Node.js runtime not found in PATH.")
  end

  -- 6. Godot toolchain (Godot itself provides GDScript LSP and DAP)
  if vim.fn.executable("godot") == 1 then
    ok("Godot editor found: " .. vim.fn.system("godot --version"):gsub("%s+", ""))
  else
    warn("Godot editor not found. Rebuild the NixOS configuration first.")
  end
end

return M
