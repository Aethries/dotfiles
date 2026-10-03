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

  -- Icons
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
  },

  -- Statusline
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "auto",
        globalstatus = true,
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { { "filename", path = 1 } },
        lualine_x = { "encoding", "fileformat", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    },
  },

  -- Git signs & diff integration
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local function bmap(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
        end

        bmap("n", "]h", gs.next_hunk, "Next Hunk")
        bmap("n", "[h", gs.prev_hunk, "Prev Hunk")
        bmap("n", "<leader>hs", gs.stage_hunk, "Stage Hunk")
        bmap("n", "<leader>hr", gs.reset_hunk, "Reset Hunk")
        bmap("n", "<leader>hp", gs.preview_hunk, "Preview Hunk")
        bmap("n", "<leader>hb", function() gs.blame_line({ full = true }) end, "Blame Line")
      end,
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
}
