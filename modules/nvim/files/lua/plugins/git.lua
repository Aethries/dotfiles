-- ==============================================================================
-- Git Integrations: LazyGit, Diffview, Git Conflict, Gitsigns, & Pickers
-- ==============================================================================

return {
  -- Gitsigns: High-performance git signs, inline hunk actions & line blame
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    cmd = { "Gitsigns" },
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

        -- Navigation
        bmap("n", "]c", function()
          if vim.wo.diff then return "]c" end
          vim.schedule(function() gs.next_hunk() end)
          return "<Ignore>"
        end, "Next Hunk")
        bmap("n", "[c", function()
          if vim.wo.diff then return "[c" end
          vim.schedule(function() gs.prev_hunk() end)
          return "<Ignore>"
        end, "Prev Hunk")

        -- Actions
        bmap("n", "<leader>hs", gs.stage_hunk, "Stage Hunk")
        bmap("n", "<leader>hr", gs.reset_hunk, "Reset Hunk")
        bmap("v", "<leader>hs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Stage Hunk")
        bmap("v", "<leader>hr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Reset Hunk")
        bmap("n", "<leader>hS", gs.stage_buffer, "Stage Buffer")
        bmap("n", "<leader>hu", gs.undo_stage_hunk, "Undo Stage Hunk")
        bmap("n", "<leader>hR", gs.reset_buffer, "Reset Buffer")
        bmap("n", "<leader>hp", gs.preview_hunk, "Preview Hunk")
        bmap("n", "<leader>hb", function() gs.blame_line({ full = true }) end, "Blame Line")
        bmap("n", "<leader>tb", gs.toggle_current_line_blame, "Toggle Line Blame")
        bmap("n", "<leader>hd", gs.diffthis, "Diff This")
        bmap("n", "<leader>hD", function() gs.diffthis("~") end, "Diff This ~")

        -- Text object
        bmap({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Select Git Hunk")
      end,
    },
  },

  -- LazyGit: Floating Terminal TUI
  {
    "kdheepak/lazygit.nvim",
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    keys = {
      { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit (Project)" },
      { "<leader>gf", "<cmd>LazyGitCurrentFile<cr>", desc = "LazyGit (Current file)" },
    },
    init = function()
      vim.g.lazygit_floating_window_winblend = 0
      vim.g.lazygit_floating_window_scaling_factor = 0.92
      vim.g.lazygit_floating_window_border_chars = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" }
      vim.g.lazygit_floating_window_use_plenary = 0
    end,
  },

  -- Diffview: Single tabpage side-by-side diff review & history
  {
    "sindrets/diffview.nvim",
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewFileHistory",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview (Open diff)" },
      { "<leader>gD", "<cmd>DiffviewClose<cr>", desc = "Diffview (Close diff)" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview (File history)" },
      { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Diffview (Branch history)" },
    },
    opts = {
      enhanced_diff_hl = true,
      use_icons = true,
      view = {
        default = {
          layout = "diff2_horizontal",
        },
        merge_tool = {
          layout = "diff3_horizontal",
        },
      },
    },
  },

  -- Git Conflict: 3-way merge conflict marker resolution
  {
    "akinsho/git-conflict.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      default_mappings = true,
      default_commands = true,
      disable_diagnostics = false,
      list_opener = "copen",
      highlights = {
        incoming = "DiffAdd",
        current = "DiffText",
      },
    },
  },

  -- Git Telescope Pickers (Commits, Branches, Status, Stash)
  {
    "nvim-telescope/telescope.nvim",
    optional = true,
    keys = {
      { "<leader>gc", "<cmd>Telescope git_commits<cr>", desc = "Git Commits" },
      { "<leader>gb", "<cmd>Telescope git_branches<cr>", desc = "Git Branches" },
      { "<leader>gs", "<cmd>Telescope git_status<cr>", desc = "Git Status" },
      { "<leader>gS", "<cmd>Telescope git_stash<cr>", desc = "Git Stash" },
    },
  },
}
