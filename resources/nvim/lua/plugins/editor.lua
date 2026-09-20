-- ==============================================================================
-- Editor Navigation, Pickers, Explorer, and Workspace Ergonomics
-- Powered by snacks.nvim and which-key.nvim (Native Only)
-- ==============================================================================

return {
  -- Seamless Ctrl+h/j/k/l navigation across Neovim and Zellij panes. The
  -- matching Zellij WASM plugin decides whether to move Zellij or forward the
  -- key into Neovim; smart-splits hands focus back at an editor edge.
  {
    "smart-splits-nvim/smart-splits.nvim",
    lazy = false,
    opts = {
      at_edge = "stop",
      zellij_move_focus_or_tab = true,
    },
    keys = {
      { "<C-h>", function() require("smart-splits").move_cursor_left() end, mode = { "n", "t" }, desc = "Move left across Neovim/Zellij" },
      { "<C-j>", function() require("smart-splits").move_cursor_down() end, mode = { "n", "t" }, desc = "Move down across Neovim/Zellij" },
      { "<C-k>", function() require("smart-splits").move_cursor_up() end, mode = { "n", "t" }, desc = "Move up across Neovim/Zellij" },
      { "<C-l>", function() require("smart-splits").move_cursor_right() end, mode = { "n", "t" }, desc = "Move right across Neovim/Zellij" },
    },
  },

  -- Keymap discovery and group documentation
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "helix",
      spec = {
        { "<leader>f", group = "file / find" },
        { "<leader>s", group = "split / search" },
        { "<leader>b", group = "buffer" },
        { "<leader>c", group = "code / lsp" },
        { "<leader>g", group = "git" },
        { "<leader>t", group = "terminal / test" },
        { "<leader>d", group = "debug" },
        { "<leader>a", group = "ai / agent" },
      },
    },
  },

  -- Unified modern UI primitives (picker, explorer, dashboard, terminal)
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      bigfile = { enabled = true },
      dashboard = { enabled = true },
      explorer = { enabled = true },
      indent = { enabled = true },
      input = { enabled = true },
      notifier = { enabled = true, timeout = 3000 },
      picker = { enabled = true },
      quickfile = { enabled = true },
      scope = { enabled = true },
      statuscolumn = { enabled = true },
      words = { enabled = true },
    },
    keys = {
      { "<leader><space>", function() Snacks.picker.smart() end, desc = "Smart find files" },
      { "<leader>,", function() Snacks.picker.buffers() end, desc = "Buffers" },
      { "<leader>/", function() Snacks.picker.grep() end, desc = "Grep text" },
      { "<leader>:", function() Snacks.picker.command_history() end, desc = "Command history" },
      { "<leader>n", function() Snacks.picker.notifications() end, desc = "Notification history" },
      { "<leader>ff", function() Snacks.picker.files() end, desc = "Find files" },
      { "<leader>fs", function() Snacks.picker.grep() end, desc = "Search string in files" },
      { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Find buffers" },
      { "<leader>fp", function() Snacks.picker.projects() end, desc = "Find projects" },
      { "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent files" },
      { "<leader>gl", function() Snacks.lazygit() end, desc = "Lazygit" },
      { "<leader>gb", function() Snacks.git.blame_line() end, desc = "Git blame line" },
    },
  },
}
