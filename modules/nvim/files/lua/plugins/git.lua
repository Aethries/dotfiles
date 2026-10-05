-- ==============================================================================
-- Git Integrations: Diffview Source Control, Gitsigns, History & LazyGit
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
      -- A check mark distinguishes staged lines from pending changes (▎).
      signs_staged_enable = true,
      signs_staged = {
        add = { text = "✓" },
        change = { text = "✓" },
        delete = { text = "✓" },
        topdelete = { text = "✓" },
        changedelete = { text = "✓" },
      },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local function bmap(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
        end

        -- Navigation
        bmap("n", "]c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
            return
          end
          vim.schedule(function() gs.next_hunk() end)
          return "<Ignore>"
        end, "Next Hunk")
        bmap("n", "[c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
            return
          end
          vim.schedule(function() gs.prev_hunk() end)
          return "<Ignore>"
        end, "Prev Hunk")

        -- Actions
        bmap("n", "<leader>hs", gs.stage_hunk, "Stage Hunk")
        bmap("n", "<leader>hr", gs.reset_hunk, "Reset Hunk")
        bmap("v", "<leader>hs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Stage Hunk")
        bmap("v", "<leader>hr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Reset Hunk")
        bmap("n", "<leader>hS", gs.stage_buffer, "Stage Buffer")
        bmap("n", "<leader>hU", gs.reset_buffer_index, "Unstage Buffer (Keep Working Tree)")
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
      { "<leader>gl", "<cmd>LazyGit<cr>", desc = "LazyGit (Project)" },
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
      "DiffviewRefresh",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      { "<leader>gg", "<cmd>DiffviewOpen<cr>", desc = "Git Source Control (Changes / Staged)" },
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview (Open diff)" },
      { "<leader>gD", "<cmd>DiffviewClose<cr>", desc = "Diffview (Close diff)" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview (File history)" },
      { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Diffview (Branch history)" },
    },
    opts = function()
      local actions = require("diffview.actions")
      local saved_chrome
      local function show_git_help(view)
        if not view.panel or view.panel.filetype ~= "DiffviewFiles" then return end
        if not saved_chrome then
          saved_chrome = { laststatus = vim.o.laststatus, statusline = vim.go.statusline }
        end
        vim.o.laststatus = 3
        vim.go.statusline = "%#DiffviewNormal# FILES: j/k Move · Enter Open · s Stage/Unstage · S Stage all · U Unstage all %= R Refresh · q Close · g? Help "
      end
      local function restore_chrome()
        if saved_chrome then
          vim.o.laststatus = saved_chrome.laststatus
          vim.go.statusline = saved_chrome.statusline
          saved_chrome = nil
        end
      end

      -- Diffview renders status + spaces before tree entries. Overlay guides
      -- without changing the panel text or the plugin's row/action indexing.
      local guides = vim.api.nvim_create_namespace("dotfiles_diffview_guides")
      vim.api.nvim_set_decoration_provider(guides, {
        on_win = function(_, _, bufnr, top, bottom)
          if vim.bo[bufnr].filetype ~= "DiffviewFiles" then return false end
          local lines = vim.api.nvim_buf_get_lines(bufnr, top, bottom, false)
          for index, line in ipairs(lines) do
            local spaces = line:match("^.[ ]([ ]+)")
            if spaces then
              for column = 2, #spaces, 2 do
                vim.api.nvim_buf_set_extmark(bufnr, guides, top + index - 1, column, {
                  virt_text = { { "│", "NvimTreeIndentMarker" } },
                  virt_text_pos = "overlay",
                  ephemeral = true,
                  hl_mode = "combine",
                })
              end
            end
          end
          return false
        end,
      })
      return {
        enhanced_diff_hl = true,
        use_icons = true,
        watch_index = true,
        show_help_hints = true,
        hooks = {
          view_opened = show_git_help,
          view_enter = show_git_help,
          view_leave = restore_chrome,
          view_closed = restore_chrome,
        },
        view = {
          default = {
            layout = "diff2_horizontal",
            winbar_info = true,
          },
          merge_tool = {
            layout = "diff3_horizontal",
            winbar_info = true,
          },
          file_history = {
            layout = "diff2_horizontal",
            winbar_info = true,
          },
        },
        file_panel = {
          listing_style = "tree",
          tree_options = { flatten_dirs = false, folder_statuses = "always" },
          win_config = {
            position = "left",
            width = 38,
            win_opts = { number = false, relativenumber = false, scrolloff = 0 },
          },
        },
        keymaps = {
          view = {
            { "n", "q", actions.close, { desc = "Close Source Control" } },
            { "n", "R", actions.refresh_files, { desc = "Refresh Source Control" } },
            { "n", "<leader>gF", actions.focus_files, { desc = "Focus Changes / Staged Files" } },
            { "n", "<leader>gD", actions.close, { desc = "Close Source Control" } },
          },
          file_panel = {
            { "n", "q", actions.close, { desc = "Close Source Control" } },
            { "n", "<leader>hs", actions.toggle_stage_entry, { desc = "Stage / Unstage File or Folder" } },
            { "n", "<leader>gD", actions.close, { desc = "Close Source Control" } },
            { "n", "<leader>gF", actions.focus_files, { desc = "Focus Changes / Staged Files" } },
          },
        },
      }
    end,
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
