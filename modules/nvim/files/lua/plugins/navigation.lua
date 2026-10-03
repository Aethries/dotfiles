return {
  -- Flash.nvim: 2D Checkpoint Hint Navigation
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash Jump" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Flash Remote" },
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Flash Treesitter Search" },
      { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
    },
  },

  -- Telescope: Fuzzy Finder
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Tìm file" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Tìm nội dung (Grep)" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Xem danh sách buffer" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Tra cứu trợ giúp" },
      { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "File đã mở gần đây" },
      { "<leader>fs", "<cmd>Telescope git_status<cr>", desc = "Git Status" },
      { "<leader>fk", "<cmd>Telescope keymaps<cr>", desc = "Xem tất cả keymap Neovim" },
      { "<leader>?", function() require("config.cheatsheet").show() end, desc = "Tra cứu phím tắt (Cheatsheet EN / VI)" },
      { "<leader>ch", function() require("config.cheatsheet").show() end, desc = "Tra cứu phím tắt (Cheatsheet EN / VI)" },
      { "<F1>", function() require("config.cheatsheet").show() end, desc = "Tra cứu phím tắt (Cheatsheet EN / VI)" },
    },
    opts = {
      defaults = {
        prompt_prefix = " ",
        selection_caret = " ",
        mappings = {
          i = {
            ["<C-j>"] = "move_selection_next",
            ["<C-k>"] = "move_selection_previous",
            ["<C-q>"] = "send_to_qflist",
          },
        },
      },
    },
  },

  -- File Explorer
  {
    "nvim-tree/nvim-tree.lua",
    cmd = { "NvimTreeToggle", "NvimTreeFocus" },
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Bật/Tắt File Explorer" },
    },
    opts = {
      filters = { dotfiles = false },
      disable_netrw = true,
      hijack_netrw = true,
      view = {
        width = 32,
        relativenumber = true,
      },
      renderer = {
        group_empty = true,
        icons = {
          show = {
            git = true,
            folder = true,
            file = true,
            folder_arrow = true,
          },
        },
      },
    },
  },

  -- Smarter subword motions (camelCase, snake_case, kebab-case)
  {
    "chrisgrieser/nvim-spider",
    keys = {
      {
        "w",
        "<cmd>lua require('spider').motion('w')<cr>",
        mode = { "n", "o", "x" },
        desc = "Spider-w (Subword)",
      },
      {
        "e",
        "<cmd>lua require('spider').motion('e')<cr>",
        mode = { "n", "o", "x" },
        desc = "Spider-e (Subword)",
      },
      {
        "b",
        "<cmd>lua require('spider').motion('b')<cr>",
        mode = { "n", "o", "x" },
        desc = "Spider-b (Subword)",
      },
      {
        "ge",
        "<cmd>lua require('spider').motion('ge')<cr>",
        mode = { "n", "o", "x" },
        desc = "Spider-ge (Subword)",
      },
    },
  },

  -- Seamless navigation between Neovim splits and Zellij panes (tmux-neovim parity)
  {
    "swaits/zellij-nav.nvim",
    event = "VeryLazy",
    keys = {
      { "<C-h>", "<cmd>ZellijNavigateLeftTab<cr>", desc = "Navigate Left (Neovim/Zellij)" },
      { "<C-j>", "<cmd>ZellijNavigateDown<cr>", desc = "Navigate Down (Neovim/Zellij)" },
      { "<C-k>", "<cmd>ZellijNavigateUp<cr>", desc = "Navigate Up (Neovim/Zellij)" },
      { "<C-l>", "<cmd>ZellijNavigateRightTab<cr>", desc = "Navigate Right (Neovim/Zellij)" },
    },
    opts = {},
  },
}
