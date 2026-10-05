return {
  -- Mason: Portable package manager for LSP servers, formatters, and linters
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    build = ":MasonUpdate",
    opts = {
      ui = {
        border = "rounded",
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    },
  },

  -- Mason bridge to lspconfig
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = {
        "lua_ls",
        "ts_ls",
        "tailwindcss",
        "html",
        "cssls",
        "emmet_language_server",
        "eslint",
        "prismals",
        "dockerls",
        "docker_compose_language_service",
        "pyright",
        "rust_analyzer",
        "gopls",
        "bashls",
        "jsonls",
        "yamlls",
        "taplo",
        "marksman",
      },
    },
  },

  -- Autocompletion engine
  {
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
    },
    opts = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      -- Load friendly-snippets (WebStorm/VSCode snippet catalog)
      require("luasnip.loaders.from_vscode").lazy_load()

      return {
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "path" },
        }, {
          { name = "buffer" },
        }),
        window = {
          completion = cmp.config.window.bordered({
            border = "rounded",
            winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
          }),
          documentation = cmp.config.window.bordered({
            border = "rounded",
            winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,Search:None",
          }),
        },
        formatting = {
          fields = { "abbr", "kind", "menu" },
          format = function(entry, item)
            local icons = {
              Text = "󰉿", Method = "󰆧", Function = "󰊕", Constructor = "",
              Field = "󰜢", Variable = "󰀫", Class = "󰠱", Interface = "",
              Module = "", Property = "󰜢", Unit = "󰑭", Value = "󰎠",
              Enum = "", Keyword = "󰌋", Snippet = "", Color = "󰏘",
              File = "󰈙", Reference = "󰈇", Folder = "󰉋", EnumMember = "",
              Constant = "󰏿", Struct = "󰙅", Event = "", Operator = "󰆕",
              TypeParameter = "󰅲",
            }
            item.kind = string.format("%s %s", icons[item.kind] or "", item.kind)
            item.menu = ({
              nvim_lsp = "[LSP]",
              luasnip = "[Snip]",
              buffer = "[Buf]",
              path = "[Path]",
              cmdline = "[Cmd]",
            })[entry.source.name]
            return item
          end,
        },
      }
    end,
    config = function(_, opts)
      local cmp = require("cmp")
      cmp.setup(opts)
      cmp.setup.cmdline(":", {
        preselect = cmp.PreselectMode.None,
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({ { name = "path" } }, {
          { name = "cmdline", option = { ignore_cmds = { "Man", "!" } } },
        }),
        window = opts.window,
      })
    end,
  },

  -- LSP Configuration
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Keymaps on LspAttach
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
        callback = function(args)
          local bufnr = args.buf
          local map = function(mode, l, r, desc)
            vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
          end

          map("n", "gd", vim.lsp.buf.definition, "Đi tới định nghĩa (Definition)")
          map("n", "gD", vim.lsp.buf.declaration, "Đi tới khai báo (Declaration)")
          map("n", "gr", vim.lsp.buf.references, "Tìm các vị trí tham chiếu (References)")
          map("n", "gi", vim.lsp.buf.implementation, "Đi tới triển khai (Implementation)")
          map("n", "K", function() vim.lsp.buf.hover({ border = "rounded" }) end, "Xem tài liệu / kiểu dữ liệu (Hover Doc)")
          map("i", "<C-k>", function() vim.lsp.buf.signature_help({ border = "rounded" }) end, "Chữ ký hàm (Signature Help)")
          map({ "n", "v" }, "<leader>ca", function()
            local ok, ap = pcall(require, "actions-preview")
            if ok then
              ap.code_actions()
            else
              vim.lsp.buf.code_action()
            end
          end, "Gợi ý sửa lỗi nhanh với xem trước (Code Action Preview)")
          map("n", "<leader>cr", vim.lsp.buf.rename, "Đổi tên symbol (Rename)")
          map("n", "<leader>cd", vim.diagnostic.open_float, "Xem chi tiết lỗi (Diagnostic)")
          map("n", "[d", vim.diagnostic.goto_prev, "Lỗi chẩn đoán trước đó")
          map("n", "]d", vim.diagnostic.goto_next, "Lỗi chẩn đoán tiếp theo")
          map("n", "<leader>ci", vim.lsp.buf.incoming_calls, "Xem các hàm gọi tới đây (Incoming Calls)")
          map("n", "<leader>co", vim.lsp.buf.outgoing_calls, "Xem các hàm được gọi từ đây (Outgoing Calls)")
          map("n", "<leader>th", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
          end, "Bật/Tắt gợi ý kiểu dữ liệu (Inlay Hints)")
        end,
      })

      -- Diagnostic signs with Nerd Font icons
      local signs = { Error = " ", Warn = " ", Hint = "󰌵 ", Info = " " }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
      end

      -- Diagnostic styling (virtual_text false for tiny-inline-diagnostic)
      vim.diagnostic.config({
        virtual_text = false,
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
          border = "rounded",
          source = "always",
        },
      })

      -- Global capabilities
      vim.lsp.config("*", {
        capabilities = capabilities,
      })

      -- Lua LSP custom settings
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
          },
        },
      })

      -- TypeScript / JavaScript Inlay Hints (WebStorm parity)
      vim.lsp.config("ts_ls", {
        settings = {
          typescript = {
            inlayHints = {
              includeInlayParameterNameHints = "all",
              includeInlayParameterNameHintsWhenArgumentMatchesName = false,
              includeInlayFunctionParameterTypeHints = true,
              includeInlayVariableTypeHints = true,
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
              includeInlayEnumMemberValueHints = true,
            },
          },
          javascript = {
            inlayHints = {
              includeInlayParameterNameHints = "all",
              includeInlayParameterNameHintsWhenArgumentMatchesName = false,
              includeInlayFunctionParameterTypeHints = true,
              includeInlayVariableTypeHints = true,
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
              includeInlayEnumMemberValueHints = true,
            },
          },
        },
      })

      -- Go LSP settings (Analyses, Inlay Hints, Staticcheck, Placeholders)
      vim.lsp.config("gopls", {
        settings = {
          gopls = {
            analyses = {
              unusedparams = true,
              shadow = true,
              nilness = true,
              unusedwrite = true,
              useany = true,
            },
            staticcheck = true,
            gofumpt = true,
            usePlaceholders = true,
            completeUnimported = true,
            hints = {
              assignVariableTypes = true,
              compositeLiteralFields = true,
              compositeLiteralTypes = true,
              constantValues = true,
              functionTypeParameters = true,
              parameterNames = true,
              rangeVariableTypes = true,
            },
          },
        },
      })

      -- Bash / Shell LSP settings
      vim.lsp.config("bashls", {
        filetypes = { "sh", "bash", "zsh" },
      })

      -- TOML LSP settings
      vim.lsp.config("taplo", {})

      -- YAML LSP settings (GitHub Workflows, Compose, K8s schemas)
      vim.lsp.config("yamlls", {
        settings = {
          yaml = {
            schemaStore = { enable = false, url = "" },
            schemas = {
              ["https://json.schemastore.org/github-workflow.json"] = ".github/workflows/*",
              ["https://json.schemastore.org/github-action.json"] = ".github/action.{yml,yaml}",
              ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = "*docker-compose*.{yml,yaml}",
              ["https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.30.0-standalone-strict/all.json"] = "*.k8s.{yml,yaml}",
            },
          },
        },
      })

      -- JSON LSP settings (package.json, tsconfig schemas)
      vim.lsp.config("jsonls", {
        settings = {
          json = {
            schemas = {
              {
                fileMatch = { "package.json" },
                url = "https://json.schemastore.org/package.json",
              },
              {
                fileMatch = { "tsconfig*.json" },
                url = "https://json.schemastore.org/tsconfig.json",
              },
            },
          },
        },
      })

      -- Emmet LSP filetypes
      vim.lsp.config("emmet_language_server", {
        filetypes = { "css", "html", "javascript", "javascriptreact", "less", "sass", "scss", "typescriptreact" },
      })

      -- Enable servers via modern native Neovim 0.11+ API
      vim.lsp.enable({
        "lua_ls",
        "ts_ls",
        "tailwindcss",
        "html",
        "cssls",
        "emmet_language_server",
        "eslint",
        "prismals",
        "dockerls",
        "docker_compose_language_service",
        "pyright",
        "rust_analyzer",
        "gopls",
        "bashls",
        "jsonls",
        "yamlls",
        "taplo",
        "marksman",
      })

      -- Enable native Inlay Hints
      vim.lsp.inlay_hint.enable(true)
    end,
  },

  -- Code Formatter (Conform.nvim)
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ async = true, lsp_fallback = true })
        end,
        mode = { "n", "v" },
        desc = "Định dạng lại file code (Format)",
      },
    },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "ruff_format", "black" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        html = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        graphql = { "prettier" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        rust = { "rustfmt" },
        go = { "gofumpt", "goimports" },
        toml = { "taplo" },
      },
      format_on_save = {
        timeout_ms = 1000,
        lsp_fallback = true,
      },
    },
  },
}
