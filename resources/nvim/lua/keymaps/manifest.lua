-- ==============================================================================
-- Keymap Manifest: Single Source of Truth
-- Shared between Native Neovim, Neovide, and Antigravity IDE
-- ==============================================================================

local M = {}

M.entries = {
  -- ----------------------------------------------------------------------------
  -- 1. Insert Mode Ergonomics
  -- ----------------------------------------------------------------------------
  {
    modes = { "i" },
    key = "jk",
    action = "editor.exit_insert",
    native = "<Esc>",
    desc = "Exit insert mode",
    group = "edit",
    scope = "editor",
  },
  {
    modes = { "i" },
    key = "kj",
    action = "editor.exit_insert",
    native = "<Esc>",
    desc = "Exit insert mode",
    group = "edit",
    scope = "editor",
  },

  -- ----------------------------------------------------------------------------
  -- 2. Word & Identifier Motions
  -- ----------------------------------------------------------------------------
  {
    modes = { "n", "o", "x" },
    key = "W",
    action = "motion.identifier_forward",
    native = "w",
    desc = "Full identifier forward",
    group = "motion",
    scope = "editor",
  },
  {
    modes = { "n", "o", "x" },
    key = "B",
    action = "motion.identifier_backward",
    native = "b",
    desc = "Full identifier backward",
    group = "motion",
    scope = "editor",
  },
  {
    modes = { "n", "o", "x" },
    key = "E",
    action = "motion.identifier_end_forward",
    native = "e",
    desc = "Forward to end of full identifier",
    group = "motion",
    scope = "editor",
  },
  {
    modes = { "n", "o", "x" },
    key = "gE",
    action = "motion.identifier_end_backward",
    native = "ge",
    desc = "Backward to end of full identifier",
    group = "motion",
    scope = "editor",
  },

  -- ----------------------------------------------------------------------------
  -- 3. Navigation & Centering
  -- ----------------------------------------------------------------------------
  {
    modes = { "n", "o", "x" },
    key = "H",
    action = "cursor.line_start",
    native = "^",
    desc = "Jump to first non-blank character",
    group = "navigation",
    scope = "editor",
  },
  {
    modes = { "n", "o", "x" },
    key = "L",
    action = "cursor.line_end",
    native = "$",
    desc = "Jump to end of line",
    group = "navigation",
    scope = "editor",
  },
  {
    modes = { "n" },
    key = "<Esc>",
    action = "search.clear_highlight",
    native = "<cmd>nohlsearch<CR>",
    desc = "Clear search highlight",
    group = "search",
    scope = "editor",
  },
  {
    modes = { "n" },
    key = "<C-d>",
    action = "cursor.scroll_down_center",
    native = "<C-d>zz",
    desc = "Scroll down and center",
    group = "navigation",
    scope = "editor",
  },
  {
    modes = { "n" },
    key = "<C-u>",
    action = "cursor.scroll_up_center",
    native = "<C-u>zz",
    desc = "Scroll up and center",
    group = "navigation",
    scope = "editor",
  },

  -- ----------------------------------------------------------------------------
  -- 4. Editing & Clipboard
  -- ----------------------------------------------------------------------------
  {
    modes = { "n", "v" },
    key = "x",
    action = "edit.delete_char_no_clipboard",
    native = '"_x',
    desc = "Delete char without polluting clipboard",
    group = "edit",
    scope = "editor",
  },
  {
    modes = { "x" },
    key = "p",
    action = "edit.paste_no_overwrite",
    native = [["_dP]],
    desc = "Paste over selection preserving clipboard",
    group = "edit",
    scope = "editor",
  },
  {
    modes = { "v" },
    key = "<",
    action = "edit.indent_left",
    native = "<gv",
    desc = "Indent left and keep selection",
    group = "edit",
    scope = "editor",
  },
  {
    modes = { "v" },
    key = ">",
    action = "edit.indent_right",
    native = ">gv",
    desc = "Indent right and keep selection",
    group = "edit",
    scope = "editor",
  },
  {
    modes = { "v" },
    key = "J",
    action = "edit.move_selection_down",
    native = ":m '>+1<CR>gv=gv",
    desc = "Move selected lines down",
    group = "edit",
    scope = "editor",
  },
  {
    modes = { "v" },
    key = "K",
    action = "edit.move_selection_up",
    native = ":m '<-2<CR>gv=gv",
    desc = "Move selected lines up",
    group = "edit",
    scope = "editor",
  },

  -- ----------------------------------------------------------------------------
  -- 5. Split & Window Navigation
  -- ----------------------------------------------------------------------------
  {
    modes = { "n" },
    key = "<C-h>",
    action = "window.navigate_left",
    native = "<C-w>h",
    vscode = "workbench.action.navigateLeft",
    desc = "Move to left window / editor group",
    group = "window",
    scope = "global_host",
  },
  {
    modes = { "n" },
    key = "<C-j>",
    action = "window.navigate_down",
    native = "<C-w>j",
    vscode = "workbench.action.navigateDown",
    desc = "Move to bottom window / editor group",
    group = "window",
    scope = "global_host",
  },
  {
    modes = { "n" },
    key = "<C-k>",
    action = "window.navigate_up",
    native = "<C-w>k",
    vscode = "workbench.action.navigateUp",
    desc = "Move to top window / editor group",
    group = "window",
    scope = "global_host",
  },
  {
    modes = { "n" },
    key = "<C-l>",
    action = "window.navigate_right",
    native = "<C-w>l",
    vscode = "workbench.action.navigateRight",
    desc = "Move to right window / editor group",
    group = "window",
    scope = "global_host",
  },
  {
    modes = { "n" },
    key = "<leader>sv",
    action = "window.split_vertical",
    native = "<cmd>vsplit<CR>",
    vscode = "workbench.action.splitEditorRight",
    desc = "Split window vertically",
    group = "window",
    scope = "editor",
  },
  {
    modes = { "n" },
    key = "<leader>sh",
    action = "window.split_horizontal",
    native = "<cmd>split<CR>",
    vscode = "workbench.action.splitEditorDown",
    desc = "Split window horizontally",
    group = "window",
    scope = "editor",
  },
  {
    modes = { "n" },
    key = "<leader>sx",
    action = "window.close_split",
    native = "<cmd>close<CR>",
    vscode = "workbench.action.closeActiveEditor",
    desc = "Close current split",
    group = "window",
    scope = "editor",
  },

  -- ----------------------------------------------------------------------------
  -- 6. Buffer & Tab Operations
  -- ----------------------------------------------------------------------------
  {
    modes = { "n" },
    key = "<S-h>",
    action = "buffer.previous",
    native = "<cmd>bprevious<CR>",
    vscode = "workbench.action.previousEditor",
    desc = "Previous buffer / tab",
    group = "buffer",
    scope = "editor",
  },
  {
    modes = { "n" },
    key = "<S-l>",
    action = "buffer.next",
    native = "<cmd>bnext<CR>",
    vscode = "workbench.action.nextEditor",
    desc = "Next buffer / tab",
    group = "buffer",
    scope = "editor",
  },
  {
    modes = { "n" },
    key = "<leader>w",
    action = "file.save",
    native = "<cmd>w<CR>",
    vscode = "workbench.action.files.save",
    desc = "Save file",
    group = "file",
    scope = "global_host",
  },
  {
    modes = { "n" },
    key = "<leader>q",
    action = "file.quit",
    native = "<cmd>q<CR>",
    vscode = "workbench.action.closeActiveEditor",
    desc = "Quit / Close editor tab",
    group = "file",
    scope = "editor",
  },
  {
    modes = { "n" },
    key = "<leader>bd",
    action = "buffer.delete",
    native = "<cmd>bdelete<CR>",
    vscode = "workbench.action.closeActiveEditor",
    desc = "Close current buffer",
    group = "buffer",
    scope = "editor",
  },

  -- ----------------------------------------------------------------------------
  -- 7. Search, Picker & Explorer
  -- ----------------------------------------------------------------------------
  {
    modes = { "n" },
    key = "<leader>e",
    action = "ui.toggle_explorer",
    native = "<cmd>lua Snacks.picker.explorer()<CR>",
    vscode = "workbench.action.toggleSidebarVisibility",
    desc = "Toggle file explorer",
    group = "ui",
    scope = "global_host",
  },
  {
    modes = { "n" },
    key = "<leader>ff",
    action = "file.find",
    native = "<cmd>lua Snacks.picker.files()<CR>",
    vscode = "workbench.action.quickOpen",
    desc = "Find files",
    group = "file",
    scope = "global_host",
  },
  {
    modes = { "n" },
    key = "<leader>fs",
    action = "file.search_text",
    native = "<cmd>lua Snacks.picker.grep()<CR>",
    vscode = "workbench.action.findInFiles",
    desc = "Find text across files",
    group = "file",
    scope = "global_host",
  },

  -- ----------------------------------------------------------------------------
  -- 8. Code Intelligence (LSP / Refactoring)
  -- ----------------------------------------------------------------------------
  {
    modes = { "n" },
    key = "<leader>ca",
    action = "code.action",
    native = "<cmd>lua vim.lsp.buf.code_action()<CR>",
    vscode = "editor.action.quickFix",
    desc = "Code action / Quick fix",
    group = "code",
    scope = "editor",
  },
  {
    modes = { "n" },
    key = "<leader>cr",
    action = "code.rename",
    native = "<cmd>lua vim.lsp.buf.rename()<CR>",
    vscode = "editor.action.rename",
    desc = "Rename symbol",
    group = "code",
    scope = "editor",
  },
  {
    modes = { "n" },
    key = "<leader>cf",
    action = "code.format",
    native = "<cmd>lua vim.lsp.buf.format({ async = true })<CR>",
    vscode = "editor.action.formatDocument",
    desc = "Format document",
    group = "code",
    scope = "editor",
  },

  -- ----------------------------------------------------------------------------
  -- 9. Terminal & AI Agent Integration
  -- ----------------------------------------------------------------------------
  {
    modes = { "n", "t" },
    key = "<leader>th",
    action = "terminal.toggle",
    native = "toggle_terminal",
    vscode = "workbench.action.terminal.toggleTerminal",
    desc = "Toggle integrated terminal",
    group = "terminal",
    scope = "global_host",
  },
  {
    modes = { "n" },
    key = "<leader>aa",
    action = "ai.toggle_agent",
    native = "toggle_terminal",
    vscode = "workbench.action.toggleAuxiliaryBar",
    desc = "Toggle AI Agent panel",
    group = "ai",
    scope = "global_host",
  },
}

-- ==============================================================================
-- Universal Modal Grammar (Issue #30 & Workstation Standards)
-- ==============================================================================
M.global_grammar = {
  {
    concept = "Instant Reset & Escape Hatch",
    key = "Esc",
    scope = "global",
    behavior = "Release all modifiers, dismiss overlays/menus, and return immediately to NORMAL (0ms latency).",
  },
  {
    concept = "Insert / Text Entry",
    key = "i",
    scope = "modal_layers",
    behavior = "Return directly to NORMAL typing mode (in Warpd: click and exit to normal).",
  },
  {
    concept = "Virtual Pointer (Mouse)",
    key = "m / Shift+m",
    scope = "universal",
    behavior = "m: Warpd Hint Mode (jump & click). Shift+m (M): Warpd Movement Mode (h/j/k/l continuous movement).",
  },
  {
    concept = "Vertical Page Scroll",
    key = "d / u",
    scope = "universal",
    behavior = "d: Scroll down (PageDown). u: Scroll up (PageUp). Synchronized across Navigate, Chromium, Terminals, Warpd.",
  },
  {
    concept = "Directional Navigation",
    key = "h / j / k / l",
    scope = "universal",
    behavior = "Left, Down, Up, Right on all text, tabs, splits, windows, and pointer movement.",
  },
  {
    concept = "Context Jump (Index)",
    key = "1 .. 9, 0",
    scope = "universal",
    behavior = "Switch tab / workspace / sublayer by numerical index across Niri, Chromium, and Zellij.",
  },
  {
    concept = "Modal Gateway",
    key = "CapsLock",
    scope = "universal",
    behavior = "Normal: tap->navigate, double-tap/RShift->super, hold->chord. In all sublayers: tap 1-touch->normal.",
  },
}

M.workstation_layers = {
  normal = {
    name = "Normal Layer",
    desc = "Default physical typing. CapsLock is the gateway.",
    ownership = "Kernel/Kanata",
  },
  navigate = {
    name = "Navigate Layer",
    desc = "Vim cursor motions (h/j/k/l), word jumps (w/e/b), page scroll (d/u), mouse (m/M).",
    ownership = "Kanata",
  },
  super = {
    name = "Super Layer",
    desc = "One-shot & chorded modifiers (a:Super, s:Shift, d:Ctrl, f:Alt), mouse (m/M).",
    ownership = "Kanata",
  },
  chromium = {
    name = "Chromium Layer",
    desc = "Browser tabs (h/l, 1..9, t, x, r), page scroll (d/u), mouse (m/M).",
    ownership = "Kanata -> Chrome/Vimium",
  },
  terminals = {
    name = "Terminals Layer",
    desc = "Zellij multiplexer (h/l:panes, 1..9:tabs, d/u:scrollback, s:sessions), mouse (m/M).",
    ownership = "Kanata -> Zellij",
  },
  niri = {
    name = "Niri Layer",
    desc = "Window manager (h/l:columns, j/k:workspaces, 1..9:jump, d/u:scroll), mouse (m/M).",
    ownership = "Kanata -> Niri",
  },
  visual = {
    name = "Visual Layer",
    desc = "Text selection & clipboard (w/e/b, h/j/k/l, y:yank, x/c:cut, p:paste, d/u:scroll).",
    ownership = "Kanata",
  },
  warpd = {
    name = "Warpd Pointer Layer",
    desc = "Keyboard-driven mouse pointer (Hint: 2-char labels, Normal: vi-keys, Grid: 3x6 matrix).",
    ownership = "Warpd",
  },
}

return M
