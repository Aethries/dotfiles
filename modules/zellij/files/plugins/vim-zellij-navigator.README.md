# vim-zellij-navigator

- Version: **0.3.0**, source revision `6d2a3e0c1d6c64daf1ed19e9ea0849259b71f180`.
- Binary: [upstream release](https://github.com/hiasr/vim-zellij-navigator/releases/download/0.3.0/vim-zellij-navigator.wasm).
- SHA256: `77e5a2f62f7c1a698caf2574493d5d75587e0fd877cfba34c48caf731c24c58d` (matches the release asset digest).
- License: MIT; see `vim-zellij-navigator.LICENSE`.

Zellij forwards Ctrl+h/j/k/l to Neovim while it is focused. The existing
`swaits/zellij-nav.nvim` mappings choose Neovim splits first, then Zellij panes
and tabs at the editor edges. Other programs use Zellij movement directly.
The bridge runs in the background with no Locked mode or autolock.
