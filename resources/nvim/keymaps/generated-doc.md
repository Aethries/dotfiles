# Unified Workstation Keymap Reference (Issue #30)

> Auto-generated from `resources/nvim/lua/keymaps/manifest.lua`. Workstation-wide single source of truth.

## 1. Universal Modal Grammar (Quy tắc bất biến toàn hệ thống)

| Khái niệm (Concept) | Phím chuẩn (Key) | Phạm vi (Scope) | Hành vi đồng bộ (Unified Behavior) |
| :--- | :--- | :--- | :--- |
| **Instant Reset & Escape Hatch** | `Esc` | global | Release all modifiers, dismiss overlays/menus, and return immediately to NORMAL (0ms latency). |
| **Insert / Text Entry** | `i` | modal_layers | Return directly to NORMAL typing mode (in Warpd: click and exit to normal). |
| **Virtual Pointer (Mouse)** | `m / Shift+m` | universal | m: Warpd Hint Mode (jump & click). Shift+m (M): Warpd Movement Mode (h/j/k/l continuous movement). |
| **Vertical Page Scroll** | `d / u` | universal | d: Scroll down (PageDown). u: Scroll up (PageUp). Synchronized across Navigate, Chromium, Terminals, Warpd. |
| **Directional Navigation** | `h / j / k / l` | universal | Left, Down, Up, Right on all text, tabs, splits, windows, and pointer movement. |
| **Context Jump (Index)** | `1 .. 9, 0` | universal | Switch tab / workspace / sublayer by numerical index across Niri, Chromium, and Zellij. |
| **Modal Gateway** | `CapsLock` | universal | Normal: tap->navigate, double-tap/RShift->super, hold->chord. In all sublayers: tap 1-touch->normal. |

## 2. Workstation Layer Hierarchy (Phân cấp Layer)

| Layer | Tên hiển thị | Trách nhiệm chính | Phần mềm chủ quản |
| :--- | :--- | :--- | :--- |
| `normal` | Normal Layer | Default physical typing. CapsLock is the gateway. | Kernel/Kanata |
| `navigate` | Navigate Layer | Vim cursor motions (h/j/k/l), word jumps (w/e/b), page scroll (d/u), mouse (m/M). | Kanata |
| `super` | Super Layer | One-shot & chorded modifiers (a:Super, s:Shift, d:Ctrl, f:Alt), mouse (m/M). | Kanata |
| `chromium` | Chromium Layer | Browser tabs (h/l, 1..9, t, x, r), page scroll (d/u), mouse (m/M). | Kanata -> Chrome/Vimium |
| `terminals` | Terminals Layer | Zellij multiplexer (h/l:panes, 1..9:tabs, d/u:scrollback, s:sessions), mouse (m/M). | Kanata -> Zellij |
| `niri` | Niri Layer | Window manager (h/l:columns, j/k:workspaces, 1..9:jump, d/u:scroll), mouse (m/M). | Kanata -> Niri |
| `visual` | Visual Layer | Text selection & clipboard (w/e/b, h/j/k/l, y:yank, x/c:cut, p:paste, d/u:scroll). | Kanata |
| `warpd` | Warpd Pointer Layer | Keyboard-driven mouse pointer (Hint: 2-char labels, Normal: vi-keys, Grid: 3x6 matrix). | Warpd |

## 3. Editor & IDE Keymaps (Neovim / Antigravity)

| Modes | Key | Group | Description | Native Action | Antigravity Action |
| :--- | :--- | :--- | :--- | :--- | :--- |
| i | `jk` | edit | Exit insert mode | `<Esc>` | - |
| i | `kj` | edit | Exit insert mode | `<Esc>` | - |
| n, o, x | `W` | motion | Full identifier forward | `w` | - |
| n, o, x | `B` | motion | Full identifier backward | `b` | - |
| n, o, x | `E` | motion | Forward to end of full identifier | `e` | - |
| n, o, x | `gE` | motion | Backward to end of full identifier | `ge` | - |
| n, o, x | `H` | navigation | Jump to first non-blank character | `^` | - |
| n, o, x | `L` | navigation | Jump to end of line | `$` | - |
| n | `<Esc>` | search | Clear search highlight | `<cmd>nohlsearch<CR>` | - |
| n | `<C-d>` | navigation | Scroll down and center | `<C-d>zz` | - |
| n | `<C-u>` | navigation | Scroll up and center | `<C-u>zz` | - |
| n, v | `x` | edit | Delete char without polluting clipboard | `"_x` | - |
| x | `p` | edit | Paste over selection preserving clipboard | `"_dP` | - |
| v | `<` | edit | Indent left and keep selection | `<gv` | - |
| v | `>` | edit | Indent right and keep selection | `>gv` | - |
| v | `J` | edit | Move selected lines down | `:m '>+1<CR>gv=gv` | - |
| v | `K` | edit | Move selected lines up | `:m '<-2<CR>gv=gv` | - |
| n | `<C-h>` | window | Move to left window / editor group | `<C-w>h` | `workbench.action.navigateLeft` |
| n | `<C-j>` | window | Move to bottom window / editor group | `<C-w>j` | `workbench.action.navigateDown` |
| n | `<C-k>` | window | Move to top window / editor group | `<C-w>k` | `workbench.action.navigateUp` |
| n | `<C-l>` | window | Move to right window / editor group | `<C-w>l` | `workbench.action.navigateRight` |
| n | `<leader>sv` | window | Split window vertically | `<cmd>vsplit<CR>` | `workbench.action.splitEditorRight` |
| n | `<leader>sh` | window | Split window horizontally | `<cmd>split<CR>` | `workbench.action.splitEditorDown` |
| n | `<leader>sx` | window | Close current split | `<cmd>close<CR>` | `workbench.action.closeActiveEditor` |
| n | `<S-h>` | buffer | Previous buffer / tab | `<cmd>bprevious<CR>` | `workbench.action.previousEditor` |
| n | `<S-l>` | buffer | Next buffer / tab | `<cmd>bnext<CR>` | `workbench.action.nextEditor` |
| n | `<leader>w` | file | Save file | `<cmd>w<CR>` | `workbench.action.files.save` |
| n | `<leader>q` | file | Quit / Close editor tab | `<cmd>q<CR>` | `workbench.action.closeActiveEditor` |
| n | `<leader>bd` | buffer | Close current buffer | `<cmd>bdelete<CR>` | `workbench.action.closeActiveEditor` |
| n | `<leader>e` | ui | Toggle file explorer | `<cmd>lua Snacks.picker.explorer()<CR>` | `workbench.action.toggleSidebarVisibility` |
| n | `<leader>ff` | file | Find files | `<cmd>lua Snacks.picker.files()<CR>` | `workbench.action.quickOpen` |
| n | `<leader>fs` | file | Find text across files | `<cmd>lua Snacks.picker.grep()<CR>` | `workbench.action.findInFiles` |
| n | `<leader>ca` | code | Code action / Quick fix | `<cmd>lua vim.lsp.buf.code_action()<CR>` | `editor.action.quickFix` |
| n | `<leader>cr` | code | Rename symbol | `<cmd>lua vim.lsp.buf.rename()<CR>` | `editor.action.rename` |
| n | `<leader>cf` | code | Format document | `<cmd>lua vim.lsp.buf.format({ async = true })<CR>` | `editor.action.formatDocument` |
| n, t | `<leader>th` | terminal | Toggle integrated terminal | `toggle_terminal` | `workbench.action.terminal.toggleTerminal` |
| n | `<leader>aa` | ai | Toggle AI Agent panel | `toggle_terminal` | `workbench.action.toggleAuxiliaryBar` |
