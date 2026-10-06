return {
  -- Flash.nvim: 2D Checkpoint Hint Navigation
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      label = {
        -- Flash otherwise uses the current-match style for single-character targets.
        format = function(opts)
          return { { opts.match.label, opts.state.opts.highlight.groups.label } }
        end,
      },
    },
    keys = {
      { "s", mode = { "n", "o" }, function() require("flash").jump() end, desc = "Flash Jump" },
      { "S", mode = { "n", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
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
      {
        "<leader>fe",
        function()
          require("telescope.builtin").find_files({
            prompt_title = "Find .env Files",
            hidden = true,
            no_ignore = true,
            search_file = ".env",
          })
        end,
        desc = "Tìm nhanh các file .env",
      },
      {
        "<leader>ge",
        function()
          require("telescope.builtin").live_grep({
            prompt_title = "Grep in .env Files",
            additional_args = function()
              return { "--hidden", "--no-ignore", "-g", ".env*" }
            end,
          })
        end,
        desc = "Tìm nội dung trong file .env",
      },
      { "<leader>?", function() require("config.cheatsheet").show() end, desc = "Tra cứu phím tắt (Cheatsheet EN / VI)" },
      { "<leader>ch", function() require("config.cheatsheet").show() end, desc = "Tra cứu phím tắt (Cheatsheet EN / VI)" },
      { "<F1>", function() require("config.cheatsheet").show() end, desc = "Tra cứu phím tắt (Cheatsheet EN / VI)" },
    },
    opts = {
      defaults = {
        winblend = 0,
        border = true,
        borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
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
      pickers = {
        find_files = {
          hidden = true,
          find_command = {
            "rg",
            "--files",
            "--hidden",
            "--no-ignore-vcs",
            "-g", "!.git/*",
            "-g", "!node_modules/*",
            "-g", "!target/*",
            "-g", "!dist/*",
            "-g", "!build/*",
            "-g", "!.next/*",
          },
        },
        live_grep = {
          additional_args = function()
            return {
              "--hidden",
              "--no-ignore-vcs",
              "-g", "!.git/*",
              "-g", "!node_modules/*",
              "-g", "!target/*",
              "-g", "!dist/*",
              "-g", "!build/*",
              "-g", "!.next/*",
            }
          end,
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
      filters = {
        dotfiles = false,
        git_ignored = false,
      },
      disable_netrw = true,
      hijack_netrw = true,
      view = {
        width = 32,
        number = false,
        relativenumber = false,
        cursorline = true,
        cursorlineopt = "line",
        preserve_window_proportions = true,
      },
      renderer = {
        group_empty = false,
        highlight_git = "name",
        root_folder_label = function(path)
          return vim.fn.fnamemodify(path, ":t")
        end,
        indent_markers = {
          enable = true,
          icons = {
            corner = "╰",
            edge = "│",
            item = "│",
            bottom = "─",
            none = " ",
          },
        },
        icons = {
          git_placement = "after",
          show = {
            git = true,
            folder = true,
            file = true,
            folder_arrow = true,
          },
          glyphs = {
            folder = {
              arrow_closed = "›",
              arrow_open = "⌄",
            },
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
    lazy = false,
    keys = {
      { "<C-h>", "<cmd>ZellijNavigateLeftTab<cr>", desc = "Navigate Left (Neovim/Zellij)" },
      { "<C-j>", "<cmd>ZellijNavigateDown<cr>", desc = "Navigate Down (Neovim/Zellij)" },
      { "<C-k>", "<cmd>ZellijNavigateUp<cr>", desc = "Navigate Up (Neovim/Zellij)" },
      { "<C-l>", "<cmd>ZellijNavigateRightTab<cr>", desc = "Navigate Right (Neovim/Zellij)" },
    },
    opts = {},
  },

  -- Harpoon (v2): Pin and hop between hot project files
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      settings = {
        save_on_toggle = true,
      },
    },
    keys = {
      { "<leader>a", function() require("harpoon"):list():add() end, desc = "Harpoon: Ghim file hiện tại (Add)" },
      { "<C-e>", function() local h = require("harpoon"); h.ui:toggle_quick_menu(h:list(), { border = "rounded" }) end, desc = "Harpoon: Menu file đã ghim" },
      { "<leader>H", function() local h = require("harpoon"); h.ui:toggle_quick_menu(h:list(), { border = "rounded" }) end, desc = "Harpoon: Menu file đã ghim" },
      { "<leader>1", function() require("harpoon"):list():select(1) end, desc = "Harpoon: Nhảy tới file 1" },
      { "<leader>2", function() require("harpoon"):list():select(2) end, desc = "Harpoon: Nhảy tới file 2" },
      { "<leader>3", function() require("harpoon"):list():select(3) end, desc = "Harpoon: Nhảy tới file 3" },
      { "<leader>4", function() require("harpoon"):list():select(4) end, desc = "Harpoon: Nhảy tới file 4" },
      { "<leader>hp", function() require("harpoon"):list():prev() end, desc = "Harpoon: File trước đó" },
      { "<leader>hn", function() require("harpoon"):list():next() end, desc = "Harpoon: File tiếp theo" },
    },
  },

  -- Trouble: Pretty diagnostics, references, symbols, quickfix
  {
    "folke/trouble.nvim",
    cmd = { "Trouble" },
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {},
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Xem toàn bộ lỗi project (Trouble)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Xem lỗi buffer hiện tại (Trouble)" },
      { "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Cây cấu trúc hàm/biến (Trouble Symbols)" },
      { "<leader>cl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", desc = "Định nghĩa & Tham chiếu LSP (Trouble)" },
      { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location List (Trouble)" },
      { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List (Trouble)" },
    },
  },
}
