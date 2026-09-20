---
name: neovim-lua
description: "Neovim Lua configuration, plugin development, LSP server setup, Treesitter, and keymap architecture. Use when customizing Neovim, authoring Lua plugins, or debugging LSP/DAP integrations."
---

# Neovim Lua & Plugin Engineering

Engineering standards for authoring high-performance, modular Neovim configurations and Lua plugins.

## Core Rules

1. **Lua Module Structure & Lazy Loading**:
   - Organize under `lua/<namespace>/` following standard runtimepath conventions.
   - Use `lazy.nvim` or native package management with explicit lazy-loading events (`VeryLazy`, filetype, keymap, or command triggers) to keep startup time under 50ms.
2. **Native Vim APIs First**:
   - Use modern Lua APIs: `vim.api.nvim_set_keymap`, `vim.keymap.set`, `vim.opt`, `vim.fs`, `vim.notify`.
   - Avoid legacy Vimscript commands (`vim.cmd[[...]]`) where native Lua APIs exist.
3. **LSP & Treesitter Architecture**:
   - Configure Language Server Protocol via `nvim-lspconfig` and modern capabilities.
   - Attach LSP keymaps and formatting commands conditionally on `on_attach(client, bufnr)` based on server capabilities (e.g. `client.server_capabilities.documentFormattingProvider`).
   - Enable Treesitter highlights, incremental selection, and textobjects.
4. **Keymap Consistency**:
   - Always specify `{ noremap = true, silent = true, desc = "Human readable description" }`.
   - Follow the repository's existing leader key and keybinding conventions (see `keymap-architecture.md`).
