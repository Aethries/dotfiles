-- ==============================================================================
-- DevOps & Fullstack Development Suite
-- Docker, GitHub (Octo), Databases (Dadbod), REST Client (Kulala), TS Tools
-- ==============================================================================

return {
  -- GitHub CLI integration: PRs, Issues, Code Reviews
  {
    "pwntester/octo.nvim",
    cmd = { "Octo" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      { "<leader>op", "<cmd>Octo pr list<cr>", desc = "GitHub PR List" },
      { "<leader>oi", "<cmd>Octo issue list<cr>", desc = "GitHub Issues List" },
      { "<leader>oa", "<cmd>Octo actions<cr>", desc = "GitHub Actions Runs" },
      { "<leader>os", "<cmd>Octo search<cr>", desc = "GitHub Search" },
    },
    opts = {
      enable_builtin = true,
      use_local_fs = true,
      default_to_projects_v2 = true,
      default_merge_method = "squash",
    },
  },

  -- LazyDocker: Interactive Container & Pod Management
  {
    "crnvl96/lazydocker.nvim",
    cmd = { "LazyDocker" },
    dependencies = { "MunifTanjim/nui.nvim" },
    keys = {
      { "<leader>kd", "<cmd>LazyDocker<cr>", desc = "LazyDocker (Containers & Pods)" },
      { "<leader>ld", "<cmd>LazyDocker<cr>", desc = "LazyDocker (Containers & Pods)" },
    },
    opts = {},
  },

  -- Database Client (Dadbod & DBUI): PostgreSQL, MySQL, Redis, SQLite
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      { "tpope/vim-dadbod", lazy = true },
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
    },
    cmd = {
      "DBUI",
      "DBUIToggle",
      "DBUIAddConnection",
      "DBUIFindBuffer",
    },
    keys = {
      { "<leader>db", "<cmd>DBUIToggle<cr>", desc = "Database Manager (Dadbod UI)" },
    },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_show_database_icon = 1
      vim.g.db_ui_winwidth = 30
      vim.g.db_ui_auto_execute_table_helpers = 1
    end,
  },

  -- TypeScript Error Translator: Human-readable TS error explanations
  {
    "dmmulroy/ts-error-translator.nvim",
    ft = { "typescript", "typescriptreact" },
    opts = {},
  },

  -- REST API Client (Kulala): Fast HTTP client for testing backend endpoints
  {
    "mistweaverco/kulala.nvim",
    ft = { "http", "rest" },
    keys = {
      { "<leader>rr", function() require("kulala").run() end, desc = "REST: Run request", ft = { "http", "rest" } },
      { "<leader>ra", function() require("kulala").run_all() end, desc = "REST: Run all requests", ft = { "http", "rest" } },
      { "<leader>ri", function() require("kulala").inspect() end, desc = "REST: Inspect request", ft = { "http", "rest" } },
      { "<leader>re", function() require("kulala").set_selected_env() end, desc = "REST: Select environment", ft = { "http", "rest" } },
    },
    opts = {
      display_mode = "split",
      split_direction = "vertical",
      default_view = "body",
    },
  },

  -- Package Info: NPM/Yarn/Bun dependency versions inside package.json
  {
    "vuki656/package-info.nvim",
    event = { "BufRead package.json" },
    dependencies = { "MunifTanjim/nui.nvim" },
    keys = {
      { "<leader>ns", function() require("package-info").show() end, desc = "Package: Show versions", ft = "json" },
      { "<leader>nu", function() require("package-info").update() end, desc = "Package: Update dependency", ft = "json" },
      { "<leader>nd", function() require("package-info").delete() end, desc = "Package: Delete dependency", ft = "json" },
      { "<leader>ni", function() require("package-info").install() end, desc = "Package: Install new dependency", ft = "json" },
    },
    opts = {
      highlights = {
        up_to_date = { fg = "#b8bb26" },
        outdated = { fg = "#fabd2f" },
      },
    },
  },

  -- Cloak: Mask sensitive secrets/passwords in .env files (prevents screen share leaks)
  {
    "laytan/cloak.nvim",
    event = { "BufReadPre .env*", "BufReadPre *.env" },
    cmd = { "CloakToggle", "CloakEnable", "CloakDisable", "CloakPreviewLine" },
    keys = {
      { "<leader>tk", "<cmd>CloakToggle<cr>", desc = "Bật/Tắt che giấu secrets .env (Cloak)" },
    },
    opts = {
      enabled = true,
      cloak_character = "*",
      highlight_group = "Comment",
      cloak_length = nil,
      try_all_patterns = true,
      patterns = {
        {
          file_pattern = ".env*",
          cloak_pattern = "=.+",
          replace = nil,
        },
      },
    },
  },
}
