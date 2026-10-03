return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
    opts = {
      ensure_installed = {
        "bash",
        "c",
        "css",
        "diff",
        "dockerfile",
        "go",
        "graphql",
        "html",
        "javascript",
        "json",
        "lua",
        "luadoc",
        "markdown",
        "markdown_inline",
        "prisma",
        "python",
        "query",
        "regex",
        "rust",
        "sql",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "yaml",
      },
      auto_install = true,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
      indent = {
        enable = true,
      },
    },
    config = function(_, opts)
      local ok, configs = pcall(require, "nvim-treesitter.configs")
      if ok then
        configs.setup(opts)
      else
        require("nvim-treesitter").setup(opts)
      end
    end,
  },

  -- Treesitter Context: Sticky function/class header pinned at top while scrolling
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      max_lines = 3,
      min_window_height = 20,
      multiline_threshold = 1,
      trim_scope = "outer",
      mode = "cursor",
    },
    keys = {
      {
        "[k",
        function()
          require("treesitter-context").go_to_context(vim.v.count1)
        end,
        desc = "Nhảy lên đầu khối context (Treesitter)",
      },
      {
        "<leader>tc",
        "<cmd>TSContextToggle<cr>",
        desc = "Bật/Tắt thanh ngữ cảnh dính (Sticky Context)",
      },
    },
  },
}
