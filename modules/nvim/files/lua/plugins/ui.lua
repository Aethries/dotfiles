local function noctalia_lualine_theme()
  local function color(group, attribute)
    local highlight = vim.api.nvim_get_hl(0, { name = group, link = false })
    local value = highlight[attribute]
    return type(value) == "number" and string.format("#%06x", value) or nil
  end

  local background = color("Pmenu", "bg")
  local foreground = color("Pmenu", "fg")
  local accent = color("PmenuSel", "bg")
  local muted = color("FloatBorder", "fg")

  if not (background and foreground and accent and muted) then
    return "base16"
  end

  local function active_sections()
    return {
      a = { fg = accent, bg = background, gui = "bold" },
      b = { fg = foreground, bg = background },
      c = { fg = foreground, bg = background },
      x = { fg = muted, bg = background },
      y = { fg = muted, bg = background },
      z = { fg = muted, bg = background },
    }
  end

  local theme = {}
  for _, mode in ipairs({ "normal", "insert", "visual", "replace", "command", "terminal" }) do
    theme[mode] = active_sections()
  end

  local inactive = { fg = muted, bg = background }
  theme.inactive = {
    a = inactive,
    b = inactive,
    c = inactive,
    x = inactive,
    y = inactive,
    z = inactive,
  }

  return theme
end

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

  -- Terminal transparency; Neovide uses native opacity over the theme surface.
  {
    "xiyaowong/transparent.nvim",
    lazy = false,
    init = function()
      vim.g.transparent_enabled = not vim.g.neovide
    end,
    keys = {
      { "<leader>tt", "<cmd>TransparentToggle<cr>", desc = "Tạm bật/tắt nền kính mờ" },
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
          "             󰏆  Neovim",
          "",
          "       a quieter space for focused work",
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

  -- Statusline: disabled to keep the bottom edge clear
  {
    "nvim-lualine/lualine.nvim",
    enabled = false,
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = noctalia_lualine_theme,
        globalstatus = true,
        component_separators = { left = "·", right = "·" },
        section_separators = { left = "", right = "" },
        disabled_filetypes = { statusline = { "dashboard", "alpha", "starter" } },
      },
      sections = {
        lualine_a = {
          "mode",
        },
        lualine_b = {
          { "branch", icon = "" },
          { "diff", symbols = { added = "+", modified = "~", removed = "-" } },
          { "diagnostics", symbols = { error = " ", warn = " ", info = " ", hint = "󰌵 " } },
        },
        lualine_c = {
          { "filename", path = 1, symbols = { modified = " ●", readonly = " " } },
        },
        lualine_y = { "filetype", "progress" },
        lualine_z = {
          { "location", icon = "" },
        },
      },
    },
  },

  -- Bufferline: one calm surface with a clear active buffer
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        mode = "buffers",
        separator_style = "thin",
        color_icons = false,
        max_name_length = 26,
        tab_size = 32,
        enforce_regular_tabs = true,
        indicator = {
          style = "none",
        },
        offsets = {
          {
            filetype = "NvimTree",
            text = "File Explorer",
            text_align = "left",
            highlight = "BufferLineBackground",
            separator = false,
          },
        },
        show_buffer_close_icons = false,
        show_close_icon = false,
        show_tab_indicators = false,
        always_show_bufferline = false,
      },
      -- Icons derive their background from this table, not the rendered groups.
      highlights = function()
        local highlights = {}
        for key, group in pairs({
          background = "BufferLineBackground",
          buffer_visible = "BufferLineBufferVisible",
          buffer_selected = "BufferLineBufferSelected",
        }) do
          highlights[key] = vim.api.nvim_get_hl(0, { name = group, link = false })
          highlights[key].default = false
        end
        return highlights
      end,
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
          win_options = { winblend = 0 },
        },
        popup = { border = { style = "rounded" }, win_options = { winblend = 0 } },
        popupmenu = { border = { style = "rounded" }, win_options = { winblend = 0 } },
        hover = { border = { style = "rounded" }, win_options = { winblend = 0 } },
        confirm = { border = { style = "rounded" }, win_options = { winblend = 0 } },
        mini = { border = { style = "rounded" }, win_options = { winblend = 0 } },
      },
    },
  },

  -- Notification popup engine
  {
    "rcarriga/nvim-notify",
    opts = {
      timeout = 3000,
      render = "compact",
      stages = "static",
      background_colour = "NormalFloat",
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
        builtin = { border = "rounded", win_options = { winblend = 0 } },
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
      win = { border = "rounded", wo = { winblend = 0 } },
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
