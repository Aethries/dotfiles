-- ==============================================================================
-- Language Server Protocol (LSP) Configuration (Native Only)
-- Modern Neovim 0.11+ LSP setup with zero Antigravity interference
-- ==============================================================================

return {
  -- Modern diagnostics, references, and quickfix list
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    opts = {},
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
      { "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols (Trouble)" },
      { "<leader>cl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", desc = "LSP Definitions / references / ... (Trouble)" },
      { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location List (Trouble)" },
      { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List (Trouble)" },
    },
  },

  -- Core LSP Config
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "saghen/blink.cmp",
    },
    opts = {
      diagnostics = {
        underline = true,
        update_in_insert = false,
        virtual_text = {
          spacing = 4,
          source = "if_many",
          prefix = "●",
        },
        severity_sort = true,
      },
      servers = {
        bashls = {},
        dockerls = {},
        -- Godot owns the GDScript language server. Keep the editor running for
        -- the project; Neovim connects to Godot 4's default LSP port.
        gdscript = {
          cmd = vim.lsp.rpc.connect("127.0.0.1", 6005),
        },
        gopls = {
          settings = {
            gopls = {
              gofumpt = true,
              analyses = {
                unusedparams = true,
              },
              staticcheck = true,
            },
          },
        },
        jsonls = {},
        lua_ls = {
          settings = {
            Lua = {
              workspace = { checkThirdParty = false },
              telemetry = { enable = false },
            },
          },
        },
        nil_ls = {},
        ts_ls = {},
        yamlls = {},
      },
    },
    config = function(_, opts)
      vim.diagnostic.config(opts.diagnostics)

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local has_blink, blink = pcall(require, "blink.cmp")
      if has_blink then
        capabilities = blink.get_lsp_capabilities(capabilities)
      end

      local on_attach = function(_, bufnr)
        local nmap = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = bufnr, desc = "LSP: " .. desc })
        end

        nmap("gd", vim.lsp.buf.definition, "Goto Definition")
        nmap("gr", vim.lsp.buf.references, "Goto References")
        nmap("gI", vim.lsp.buf.implementation, "Goto Implementation")
        nmap("gy", vim.lsp.buf.type_definition, "Type Definition")
        nmap("K", vim.lsp.buf.hover, "Hover Documentation")
        nmap("gK", vim.lsp.buf.signature_help, "Signature Documentation")
        nmap("<leader>cr", vim.lsp.buf.rename, "Rename Symbol")
        nmap("<leader>ca", vim.lsp.buf.code_action, "Code Action")
      end

      for server, config in pairs(opts.servers) do
        config.capabilities = vim.tbl_deep_extend("force", {}, capabilities, config.capabilities or {})
        config.on_attach = on_attach
        vim.lsp.config(server, config)
        vim.lsp.enable(server)
      end
    end,
  },
}
