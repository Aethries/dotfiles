-- ==============================================================================
-- Developer Experience (DX) Power Suite
-- Treesitter Split/Join, Smart Text Objects, Doc Gen, Refactoring, Yazi, Outline, AI
-- ==============================================================================

return {
  -- TreeSJ: 1-Key Split & Join code structures (objects, arrays, JSX props, params)
  {
    "Wansmer/treesj",
    cmd = { "TSJToggle", "TSJSplit", "TSJJoin" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    keys = {
      {
        "<leader>j",
        function()
          require("treesj").toggle()
        end,
        desc = "Split / Join khối code (TreeSJ)",
      },
    },
    opts = {
      use_default_keymaps = false,
      max_join_length = 150,
    },
  },

  -- Mini.ai: Extended smart text objects (inside/around functions, arguments, classes)
  {
    "echasnovski/mini.ai",
    event = { "BufReadPost", "BufNewFile" },
    opts = function()
      local ai = require("mini.ai")
      return {
        n_lines = 500,
        custom_textobjects = {
          o = ai.gen_spec.treesitter({
            a = { "@block.outer", "@conditional.outer", "@loop.outer" },
            i = { "@block.inner", "@conditional.inner", "@loop.inner" },
          }),
          f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
          c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
          t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^<>]->$" },
        },
      }
    end,
  },

  -- Neogen: Automatic typed docstring generator (JSDoc, TSDoc, LuaDoc, Python)
  {
    "danymat/neogen",
    cmd = "Neogen",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    keys = {
      {
        "<leader>ng",
        function()
          require("neogen").generate()
        end,
        desc = "Tạo chú thích tự động (JSDoc / TSDoc)",
      },
    },
    opts = {
      snippet_engine = "luasnip",
      languages = {
        typescript = { template = { annotation_convention = "tsdoc" } },
        typescriptreact = { template = { annotation_convention = "tsdoc" } },
        javascript = { template = { annotation_convention = "jsdoc" } },
        javascriptreact = { template = { annotation_convention = "jsdoc" } },
      },
    },
  },

  -- Yazi: Embedded visual file manager in floating popup with Noctalia theme
  {
    "mikavilpas/yazi.nvim",
    cmd = { "Yazi" },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      {
        "<leader>y",
        function()
          require("yazi").yazi()
        end,
        desc = "Mở Yazi file manager (Thư mục hiện tại)",
      },
      {
        "<leader>Y",
        function()
          require("yazi").yazi(nil, vim.fn.getcwd())
        end,
        desc = "Mở Yazi file manager (Gốc dự án)",
      },
    },
    opts = {
      open_for_directories = false,
      floating_window_scaling_factor = 0.9,
      yazi_floating_window_border = "rounded",
    },
  },

  -- Refactoring: Extract function, extract variable, inline variable
  {
    "ThePrimeagen/refactoring.nvim",
    cmd = { "Refactor" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "lewis6991/async.nvim",
    },
    keys = {
      {
        "<leader>re",
        function()
          require("refactoring").select_refactor()
        end,
        mode = { "n", "v" },
        desc = "Menu tái cấu trúc mã (Refactor)",
      },
      {
        "<leader>rf",
        function()
          require("refactoring").refactor("Extract Function")
        end,
        mode = "v",
        desc = "Trích xuất thành hàm riêng (Extract Function)",
      },
      {
        "<leader>rv",
        function()
          require("refactoring").refactor("Extract Variable")
        end,
        mode = "v",
        desc = "Trích xuất thành biến (Extract Variable)",
      },
      {
        "<leader>ri",
        function()
          require("refactoring").refactor("Inline Variable")
        end,
        mode = { "n", "v" },
        desc = "Gộp biến vào biểu thức (Inline Variable)",
      },
    },
    opts = {},
  },

  -- Aerial: Code symbol outline sidebar (Functions, Components, Classes, Types)
  {
    "stevearc/aerial.nvim",
    cmd = { "AerialToggle", "AerialNavToggle" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      { "<leader>O", "<cmd>AerialToggle! left<cr>", desc = "Bật/Tắt cây cấu trúc code (Code Outline)" },
      { "<leader>ao", "<cmd>AerialToggle! left<cr>", desc = "Bật/Tắt cây cấu trúc code (Aerial Outline)" },
      { "<leader>aO", "<cmd>AerialNavToggle<cr>", desc = "Xem cấu trúc code nổi (Floating Outline)" },
    },
    opts = {
      backends = { "lsp", "treesitter" },
      layout = {
        max_width = { 40, 0.25 },
        default_direction = "left",
      },
      show_guides = true,
      filter_kind = false,
    },
  },

  -- Supermaven: Blazing-fast inline AI code completions (Free tier, zero latency)
  {
    "supermaven-inc/supermaven-nvim",
    event = "InsertEnter",
    opts = {
      keymaps = {
        accept_suggestion = "<C-f>",
        clear_suggestion = "<C-]>",
        accept_word = "<C-j>",
      },
      color = {
        suggestion_color = "#76706c",
        cterm = 244,
      },
      disable_inline_completion = false,
      disable_keymaps = false,
    },
  },

  -- Template String: Automatically convert quotes to backticks when typing ${ in JS/TS
  {
    "axelvc/template-string.nvim",
    ft = { "javascript", "typescript", "javascriptreact", "typescriptreact", "python", "vue", "svelte" },
    opts = {
      filetypes = {
        "javascript",
        "typescript",
        "javascriptreact",
        "typescriptreact",
        "vue",
        "svelte",
        "python",
      },
      jsx_brackets = true,
      remove_template_string = false,
      restore_quotes = {
        normal = [[']],
        jsx = [["]],
      },
    },
  },

  -- CCC: Advanced interactive Color Picker & Color converter popup (VSCode Color Picker)
  {
    "uga-rosa/ccc.nvim",
    cmd = { "CccPick", "CccConvert", "CccPrev", "CccNext" },
    keys = {
      { "<leader>cp", "<cmd>CccPick<cr>", desc = "Mở bảng chọn mã màu tương tác (Color Picker)" },
    },
    opts = {
      highlighter = {
        auto_enable = false,
        lsp = false,
      },
      point_char = "●",
      bar_char = "█",
    },
    config = function(_, opts)
      -- Fix Neovim 0.12 tbl_deep_extend cycle with ccc default ui metatable
      local default = require("ccc.config.default")
      default.ui = nil
      require("ccc").setup(opts)
    end,
  },

  -- Actions Preview: Rich diff preview modal before applying code actions (VSCode Code Actions Preview)
  {
    "aznhe21/actions-preview.nvim",
    cmd = { "ActionsPreview" },
    dependencies = { "nvim-telescope/telescope.nvim" },
    keys = {
      {
        "<leader>ca",
        function()
          require("actions-preview").code_actions()
        end,
        mode = { "n", "v" },
        desc = "Xem trước gợi ý sửa lỗi (Code Actions Preview)",
      },
    },
    opts = {
      telescope = {
        sorting_strategy = "ascending",
        layout_strategy = "vertical",
        layout_config = {
          width = 0.8,
          height = 0.9,
          prompt_position = "top",
          preview_cutoff = 20,
          preview_height = 0.5,
        },
      },
    },
  },
}
