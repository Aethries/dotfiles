return {
  -- Surround: Add, change, and delete surrounding delimiters (quotes, brackets, tags, JSX)
  {
    "kylechui/nvim-surround",
    version = "*",
    event = { "BufReadPost", "BufNewFile" },
    init = function()
      -- Map 'sa' in visual mode to surround selection (e.g. sa(, sa<, sa", sa', sa[, sat)
      vim.keymap.set("x", "sa", "<Plug>(nvim-surround-visual)", {
        desc = "Surround visual selection (sa)",
        silent = true,
      })
      vim.keymap.set("x", "sA", "<Plug>(nvim-surround-visual-line)", {
        desc = "Surround visual selection line (sA)",
        silent = true,
      })
    end,
    opts = {
      surrounds = {
        -- React Fragment: <> ... </>
        ["f"] = {
          add = { "<>", "</>" },
        },
        -- JSX Comment: {/* ... */}
        ["c"] = {
          add = { "{/* ", " */}" },
        },
        -- Template Literal Expression: ${ ... }
        ["e"] = {
          add = { "${", "}" },
        },
        -- JSX Expression Container: { ... }
        ["j"] = {
          add = { "{", "}" },
        },
      },
    },
  },

  -- Multi-Cursor (Vim Visual Multi): VSCode/Sublime-like multiple cursors
  {
    "mg979/vim-visual-multi",
    branch = "master",
    event = { "BufReadPost", "BufNewFile" },
    init = function()
      vim.g.VM_default_mappings = 0
      vim.g.VM_maps = {
        ["Find Under"] = "<C-n>",
        ["Find Subword Under"] = "<C-n>",
        ["Select All"] = "<leader>ma",
        ["Add Cursor Up"] = "<leader>mk",
        ["Add Cursor Down"] = "<leader>mj",
      }
      -- Styling matching Noctalia Material You palette
      vim.g.VM_theme = "purplegray"
      vim.g.VM_set_statusline = 0
    end,
  },

  -- Autopairs: Auto-close brackets, quotes, and HTML/JSX tags
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {
      check_ts = true,
      ts_config = {
        lua = { "string", "source" },
        javascript = { "string", "template_string" },
        typescript = { "string", "template_string" },
      },
      fast_wrap = {
        map = "<M-e>",
        chars = { "{", "[", "(", '"', "'" },
        pattern = [=[[%'%"%)%>%]%)%}%,]]=],
        end_key = "$",
        keys = "qwertyuiopzxcvbnmasdfghjkl",
        check_comma = true,
        highlight = "Search",
        highlight_grey = "Comment",
      },
    },
    config = function(_, opts)
      local npairs = require("nvim-autopairs")
      local Rule = require("nvim-autopairs.rule")
      local cond = require("nvim-autopairs.conds")

      npairs.setup(opts)

      -- Auto-close < > for generics/tags when not preceded by space
      npairs.add_rule(
        Rule("<", ">")
          :with_pair(cond.not_before_regex("%s"))
          :with_pair(cond.not_after_regex("[%w]"))
          :with_move(function(o)
            return o.char == ">"
          end)
      )

      -- Integrate with nvim-cmp
      local ok, cmp = pcall(require, "cmp")
      if ok then
        local cmp_autopairs = require("nvim-autopairs.completion.cmp")
        cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
      end
    end,
  },

  -- Autotag: Automatically close and rename HTML/JSX/XML tags via Treesitter
  {
    "windwp/nvim-ts-autotag",
    event = { "BufReadPre", "BufNewFile" },
    opts = {},
  },

  -- Todo Comments: Highlight and search TODO, FIXME, NOTE, HACK, PERF
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "TodoTelescope", "TodoQuickFix", "TodoLocList" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      signs = true,
    },
    config = function(_, opts)
      require("todo-comments").setup(opts)
      require("todo-comments.config")._setup()
    end,
    keys = {
      { "]t", function() require("todo-comments").jump_next() end, desc = "Next TODO comment" },
      { "[t", function() require("todo-comments").jump_prev() end, desc = "Previous TODO comment" },
      { "<leader>ft", "<cmd>TodoTelescope<cr>", desc = "Tìm tất cả TODO / FIXME" },
    },
  },

  -- Session Persistence: Automatic and on-demand session management
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    keys = {
      { "<leader>qs", function() require("persistence").load() end, desc = "Khôi phục phiên làm việc (Session)" },
      { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Khôi phục phiên gần nhất (Last Session)" },
      { "<leader>qd", function() require("persistence").stop() end, desc = "Dừng lưu phiên làm việc" },
    },
    opts = {
      options = vim.opt.sessionoptions:get(),
    },
  },

  -- Inc-Rename: Live incremental LSP symbol renaming with real-time preview
  {
    "smjonas/inc-rename.nvim",
    cmd = "IncRename",
    opts = {},
    keys = {
      {
        "<leader>rn",
        function()
          return ":IncRename " .. vim.fn.expand("<cword>")
        end,
        expr = true,
        desc = "Đổi tên symbol trực tiếp (Live Rename)",
      },
      {
        "<leader>cr",
        function()
          return ":IncRename " .. vim.fn.expand("<cword>")
        end,
        expr = true,
        desc = "Đổi tên symbol trực tiếp (Live Rename)",
      },
    },
  },

  -- Grug-Far: Lightning-fast project-wide search and replace (VSCode Search & Replace parity)
  {
    "MagicDuck/grug-far.nvim",
    cmd = { "GrugFar", "GrugFarWithin" },
    keys = {
      {
        "<leader>sr",
        function()
          require("grug-far").open()
        end,
        desc = "Tìm và thay thế toàn dự án (Search & Replace)",
      },
      {
        "<leader>sw",
        function()
          require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } })
        end,
        desc = "Tìm và thay thế từ tại con trỏ (GrugFar Word)",
      },
      {
        "<leader>sr",
        function()
          require("grug-far").with_visual_selection()
        end,
        mode = "v",
        desc = "Tìm và thay thế vùng chọn (GrugFar Visual)",
      },
    },
    opts = {
      headerMaxWidth = 80,
    },
  },

  -- Auto-Save: Automatic buffer saving on focus loss / idle (VSCode/WebStorm parity)
  {
    "okuuva/auto-save.nvim",
    cmd = "ASToggle",
    event = { "InsertLeave", "TextChanged" },
    keys = {
      { "<leader>as", "<cmd>ASToggle<cr>", desc = "Bật/Tắt tự động lưu file (Auto-Save)" },
      { "<leader>ta", "<cmd>ASToggle<cr>", desc = "Bật/Tắt tự động lưu file (Auto-Save)" },
    },
    opts = {
      enabled = true,
      trigger_events = {
        immediate_save = { "BufLeave", "FocusLost" },
        defer_save = { "InsertLeave", "TextChanged" },
        cancel_deferred_save = { "InsertEnter" },
      },
      debounce_delay = 1000,
      condition = function(buf)
        -- Writing Diffview's index buffers changes staging; require an explicit save.
        if vim.api.nvim_buf_get_name(buf):match("^diffview://") then
          return false
        end
        local fn = vim.fn
        local utils = require("auto-save.utils.data")
        if fn.getbufvar(buf, "&modifiable") == 1 and
           utils.not_in(fn.getbufvar(buf, "&filetype"), { "gitcommit", "oil", "TelescopePrompt", "octo" }) then
          return true
        end
        return false
      end,
      write_all_buffers = false,
    },
  },
}
