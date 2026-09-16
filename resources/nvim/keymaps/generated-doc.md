# Unified Keymap Reference

> Auto-generated from `manifest.lua`. Single source of truth across Neovim, Neovide, and Antigravity IDE.

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
