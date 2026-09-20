-- ==============================================================================
-- Test Runner: Neotest (Native Only)
-- Unified test execution for Go, Vitest, and Jest
-- ==============================================================================

return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-neotest/neotest-go",
      "marilari88/neotest-vitest",
      "nvim-neotest/neotest-jest",
    },
    keys = {
      { "<leader>tr", function() require("neotest").run.run() end, desc = "Run Nearest Test" },
      { "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run Test File" },
      { "<leader>ts", function() require("neotest").run.run({ suite = true }) end, desc = "Run Test Suite" },
      { "<leader>tl", function() require("neotest").run.run_last() end, desc = "Run Last Test" },
      { "<leader>to", function() require("neotest").output.open({ enter = true }) end, desc = "Show Test Output" },
      { "<leader>tS", function() require("neotest").summary.toggle() end, desc = "Toggle Test Summary" },
    },
    opts = function()
      return {
        adapters = {
          require("neotest-go")({
            recursive_run = true,
          }),
          require("neotest-vitest")({}),
          require("neotest-jest")({
            jestCommand = "npm test --",
            jestConfigFile = function()
              local cwd = vim.fn.getcwd()
              for _, name in ipairs({ "custom.jest.config.ts", "jest.config.ts", "jest.config.js", "jest.config.cjs" }) do
                if vim.fn.filereadable(cwd .. "/" .. name) == 1 then return name end
              end
              return "jest.config.ts"
            end,
            env = { CI = true },
            cwd = function()
              return vim.fn.getcwd()
            end,
          }),
        },
      }
    end,
  },
}
