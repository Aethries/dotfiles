return {
  -- Base16 theme engine (required for Noctalia Matugen dynamic palette)
  {
    "RRethy/base16-nvim",
    lazy = false,
    priority = 1000,
    config = function()
      pcall(function()
        require("matugen").setup()
      end)
    end,
  },

  -- Transparent background & Glassmorphism (Kitty 0.85 opacity + 32px blur)
  {
    "xiyaowong/transparent.nvim",
    lazy = false,
    keys = {
      { "<leader>tt", "<cmd>TransparentToggle<cr>", desc = "Bật/Tắt nền trong suốt (Kính mờ)" },
    },
    opts = {
      groups = {
        "Normal",
        "NormalNC",
        "Comment",
        "Constant",
        "Special",
        "Identifier",
        "Statement",
        "PreProc",
        "Type",
        "Underlined",
        "Todo",
        "String",
        "Function",
        "Conditional",
        "Repeat",
        "Operator",
        "Structure",
        "LineNr",
        "NonText",
        "SignColumn",
        "CursorLineNr",
        "EndOfBuffer",
      },
      extra_groups = {
        "NvimTreeNormal",
        "NvimTreeNormalNC",
        "NvimTreeEndOfBuffer",
        "TelescopeNormal",
        "TelescopeBorder",
        "TelescopePromptNormal",
        "TelescopePromptBorder",
        "BufferLineFill",
        "BufferLineBackground",
      },
    },
  },

  -- Icons
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
  },

  -- Dashboard: Modern Aesthetic Startup Screen
  {
    "nvimdev/dashboard-nvim",
    event = "VimEnter",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      theme = "doom",
      config = {
        header = {
          "",
          " ███╗   ██╗ ██████╗  ██████╗████████╗ █████╗ ██╗     ██╗ █████╗ ",
          " ████╗  ██║██╔═══██╗██╔════╝╚══██╔══╝██╔══██╗██║     ██║██╔══██╗",
          " ██╔██╗ ██║██║   ██║██║        ██║   ███████║██║     ██║███████║",
          " ██║╚██╗██║██║   ██║██║        ██║   ██╔══██║██║     ██║██╔══██║",
          " ██║ ╚████║╚██████╔╝╚██████╗   ██║   ██║  ██║███████╗██║██║  ██║",
          " ╚═╝  ╚═══╝ ╚═════╝  ╚═════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝╚═╝  ╚═╝",
          "",
          "        ✨ Noctalia Dynamic Workspace • Material You ✨        ",
          "",
        },
        center = {
          {
            icon = " ",
            key = "f",
            desc = "Find File (Tìm file)             ",
            action = "Telescope find_files",
          },
          {
            icon = " ",
            key = "r",
            desc = "Recent Files (File gần đây)      ",
            action = "Telescope oldfiles",
          },
          {
            icon = " ",
            key = "g",
            desc = "Live Grep (Tìm nội dung)         ",
            action = "Telescope live_grep",
          },
          {
            icon = " ",
            key = "b",
            desc = "Open Buffers (Buffer đang mở)    ",
            action = "Telescope buffers",
          },
          {
            icon = "󰋖 ",
            key = "?",
            desc = "Cheatsheet (Tra cứu phím tắt)    ",
            action = function()
              require("config.cheatsheet").show()
            end,
          },
          {
            icon = " ",
            key = "q",
            desc = "Quit (Thoát)                     ",
            action = "qa",
          },
        },
        footer = function()
          local stats = require("lazy").stats()
          local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
          return { "⚡ Loaded " .. stats.loaded .. "/" .. stats.count .. " plugins in " .. ms .. "ms" }
        end,
      },
    },
  },

  -- Statusline: Modern Bubble Pill Style
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "base16",
        globalstatus = true,
        component_separators = "",
        section_separators = { left = "", right = "" },
        disabled_filetypes = { statusline = { "dashboard", "alpha", "starter" } },
      },
      sections = {
        lualine_a = {
          { "mode", separator = { left = "", right = "" }, icon = "" },
        },
        lualine_b = {
          { "branch", icon = "" },
          { "diff", symbols = { added = "+", modified = "~", removed = "-" } },
          { "diagnostics", symbols = { error = " ", warn = " ", info = " ", hint = "󰌵 " } },
        },
        lualine_c = {
          { "filename", path = 1, symbols = { modified = " ●", readonly = " " } },
        },
        lualine_x = {
          {
            function()
              local clients = vim.lsp.get_clients({ bufnr = 0 })
              if #clients == 0 then return "" end
              local names = {}
              for _, client in ipairs(clients) do
                table.insert(names, client.name)
              end
              return " " .. table.concat(names, ", ")
            end,
            cond = function() return #vim.lsp.get_clients({ bufnr = 0 }) > 0 end,
          },
          "encoding",
          "filetype",
        },
        lualine_y = { "progress" },
        lualine_z = {
          { "location", separator = { left = "", right = "" }, icon = "" },
        },
      },
    },
  },

  -- Bufferline: Tabs at top with Slanted styling & devicons
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        mode = "buffers",
        separator_style = "slant",
        diagnostics = "nvim_lsp",
        diagnostics_indicator = function(count, level)
          local icon = level:match("error") and " " or " "
          return " " .. icon .. count
        end,
        indicator = {
          style = "icon",
          icon = "▎",
        },
        offsets = {
          {
            filetype = "NvimTree",
            text = "File Explorer",
            text_align = "left",
            separator = true,
          },
        },
        show_buffer_close_icons = false,
        show_close_icon = false,
        always_show_bufferline = true,
      },
    },
  },

  -- Noice: Floating Command Palette, Search Modal, and Popup Docs
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    opts = {
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
      },
      presets = {
        bottom_search = false,
        command_palette = true,
        long_message_to_split = true,
        inc_rename = true,
        lsp_doc_border = true,
      },
      views = {
        cmdline_popup = {
          border = {
            style = "rounded",
            padding = { 0, 1 },
          },
        },
      },
    },
  },

  -- Notification popup engine
  {
    "rcarriga/nvim-notify",
    opts = {
      timeout = 3000,
      render = "compact",
      stages = "fade",
      background_colour = "#000000",
    },
  },


  -- Indent Guides: Clean vertical structure markers
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      indent = {
        char = "│",
        tab_char = "│",
      },
      scope = {
        enabled = true,
        show_start = false,
        show_end = false,
        highlight = { "IblScope" },
      },
      exclude = {
        filetypes = { "help", "NvimTree", "lazy", "mason", "notify", "telescope", "dashboard" },
      },
    },
  },

  -- Dressing: Polished floating UI for select and input dialogs
  {
    "stevearc/dressing.nvim",
    event = "VeryLazy",
    opts = {
      input = {
        border = "rounded",
        win_options = { winblend = 0 },
      },
      select = {
        backend = { "telescope", "builtin" },
      },
    },
  },

  -- Highlight Colors: Live hex/rgb swatches directly in editor
  {
    "brenoprata10/nvim-highlight-colors",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      render = "virtual",
      virtual_symbol = "■",
      enable_hex = true,
      enable_rgb = true,
      enable_hsl = true,
      enable_var_usage = true,
    },
  },


  -- Keymap helper popup
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "helix",
    },
  },

  -- Render Markdown: In-editor GitHub-style rich markdown (Callouts, Tables, Checkboxes, Badges)
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      { "<leader>tm", "<cmd>RenderMarkdown toggle<cr>", desc = "Bật/Tắt hiển thị Markdown đẹp (Render Markdown)" },
    },
    opts = {
      heading = {
        icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
      },
      code = {
        sign = false,
        width = "block",
        right_pad = 1,
      },
    },
  },

  -- Rainbow Delimiters: Color nested brackets/parentheses by depth
  {
    "HiPhish/rainbow-delimiters.nvim",
    submodules = false,
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local rainbow_delimiters = require("rainbow-delimiters")
      vim.g.rainbow_delimiters = {
        strategy = {
          [""] = rainbow_delimiters.strategy["global"],
          vim = rainbow_delimiters.strategy["local"],
        },
        query = {
          [""] = "rainbow-delimiters",
          lua = "rainbow-blocks",
        },
        priority = {
          [""] = 110,
          lua = 210,
        },
        highlight = {
          "RainbowDelimiterRed",
          "RainbowDelimiterYellow",
          "RainbowDelimiterBlue",
          "RainbowDelimiterOrange",
          "RainbowDelimiterGreen",
          "RainbowDelimiterViolet",
          "RainbowDelimiterCyan",
        },
      }
    end,
  },

  -- Tiny Inline Diagnostic: Multi-line floating diagnostics beneath error lines
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "LspAttach",
    priority = 1000,
    opts = {
      preset = "modern",
      transparent_bg = true,
      options = {
        show_source = true,
        use_icons_from_diagnostic = true,
        multilines = true,
      },
    },
  },
}
