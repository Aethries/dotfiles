---
name: neovim-lua
description: "Neovim Lua configuration, plugin development, LSP server setup, Treesitter, and keymap architecture. Use when customizing Neovim, authoring Lua plugins, or debugging LSP/DAP integrations."
---

# Neovim Lua & Plugin Engineering

Engineering standards for authoring high-performance, modular Neovim configurations and Lua plugins.

## Core Rules

1. **Inspect Neovim Environment & Package Management First**:
   - Inspect how Neovim is packaged and managed in the environment (e.g. Nix Flakes / Home Manager `programs.neovim`, `lazy.nvim`, `mini.deps`, `pckr`, or native `packpath`). Never impose `lazy.nvim` or external managers if the config is Nix-managed or native.
   - Inspect existing configuration files under `init.lua`, `lua/`, and `resources/nvim/` to follow established module structures and conventions.
2. **Native Vim Lua APIs First**:
   - Use modern Lua APIs: `vim.keymap.set`, `vim.api.*`, `vim.opt`, `vim.fs`, `vim.notify`, `vim.iter`.
   - Avoid legacy Vimscript strings (`vim.cmd[[...]]`) where native Lua APIs exist.
3. **LSP & Treesitter Architecture**:
   - Integrate with the repository's active LSP management (native Neovim 0.10+ `vim.lsp.enable` / `vim.lsp.buf` or plugin wrappers).
   - Attach buffer-local keymaps and formatting conditionally based on `client.supports_method("textDocument/formatting")`.
   - Enable Treesitter highlights, textobjects, and folds aligned with the host build mechanism.
4. **Keymap & Option Consistency**:
   - Always specify descriptive options `{ desc = "...", silent = true }`.
   - Respect the repository's existing leader key conventions (`<Space>`, `\`) and modular keymap architecture.
