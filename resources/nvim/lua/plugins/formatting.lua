-- ==============================================================================
-- Deterministic Code Formatting & Linting (Native Only)
-- Conform.nvim & nvim-lint
-- ==============================================================================

return {
  -- Deterministic Formatter
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    cond = not vim.g.vscode,
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        go = { "goimports", "gofumpt" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        nix = { "nixfmt" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        python = { "ruff_format" },
      },
      format_on_save = {
        timeout_ms = 1500,
        lsp_format = "fallback",
      },
    },
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ async = true, lsp_format = "fallback" })
        end,
        desc = "Format Document",
      },
    },
  },

  -- Fast Asynchronous Linter
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufWritePost" },
    cond = not vim.g.vscode,
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = {
        sh = { "shellcheck" },
        bash = { "shellcheck" },
      }

      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("LintingAutocmd", { clear = true }),
        callback = function()
          lint.try_lint()
        end,
      })
    end,
  },
}
