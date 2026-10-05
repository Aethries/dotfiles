local raster_patterns = {
  "*.png", "*.jpg", "*.jpeg", "*.webp", "*.gif", "*.bmp", "*.tif", "*.tiff", "*.avif",
  "*.PNG", "*.JPG", "*.JPEG", "*.WEBP", "*.GIF", "*.BMP", "*.TIF", "*.TIFF", "*.AVIF",
}

return {
  {
    "3rd/image.nvim",
    build = false,
    cond = function()
      return not vim.g.neovide and (
        vim.env.TERM_PROGRAM == "ghostty" or vim.env.TERM == "xterm-kitty" or vim.env.KITTY_WINDOW_ID ~= nil
      )
    end,
    opts = {
      backend = "kitty",
      processor = "magick_cli",
      -- Focal owns image buffers and previews; avoid two competing renderers.
      hijack_file_patterns = {},
      integrations = {
        markdown = { enabled = false },
        asciidoc = { enabled = false },
        neorg = { enabled = false },
        rst = { enabled = false },
        typst = { enabled = false },
        html = { enabled = false },
        css = { enabled = false },
      },
    },
  },
  {
    "hmdfrds/focal.nvim",
    event = "VeryLazy",
    cmd = { "FocalShow", "FocalHide", "FocalEnable", "FocalDisable", "FocalToggle", "FocalStatus" },
    dependencies = { "3rd/image.nvim" },
    keys = {
      {
        "<leader>ip",
        function()
          local focal = require("focal")
          focal.enable()
          if vim.bo.filetype == "NvimTree" then
            focal.show()
          else
            focal.show(vim.api.nvim_buf_get_name(0))
          end
        end,
        desc = "Preview ảnh hiện tại / ảnh trong Explorer",
      },
      { "<leader>iP", "<cmd>FocalDisable<cr>", desc = "Ẩn preview ảnh và tạm dừng tự động" },
    },
    opts = {
      backend = vim.g.neovide and "chafa" or "auto",
      border = "rounded",
      winblend = 0,
      debounce_ms = 180,
      max_width_percent = 60,
      max_height_percent = 70,
      max_file_size_mb = 20,
      chafa = { format = "symbols", animate = false },
    },
    init = function()
      local group = vim.api.nvim_create_augroup("DotfilesImagePreview", { clear = true })
      -- Do not read binary image data into an editable source buffer.
      vim.api.nvim_create_autocmd("BufReadCmd", {
        group = group,
        pattern = raster_patterns,
        callback = function(event)
          vim.api.nvim_buf_set_lines(event.buf, 0, -1, false, {
            "Image · " .. vim.fn.fnamemodify(event.file, ":t"),
            "",
            "Preview opens automatically. Space ip: show · Space iP: hide",
          })
          vim.bo[event.buf].buftype = "nofile"
          vim.bo[event.buf].swapfile = false
          vim.bo[event.buf].modified = false
          vim.bo[event.buf].modifiable = false
          vim.bo[event.buf].filetype = "imagepreview"
        end,
      })
      vim.api.nvim_create_autocmd("BufWinEnter", {
        group = group,
        callback = function(event)
          local extension = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(event.buf), ":e"):lower()
          if vim.bo[event.buf].filetype ~= "imagepreview" and extension ~= "svg" then return end
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(event.buf) and vim.api.nvim_get_current_buf() == event.buf then
              require("lazy").load({ plugins = { "focal.nvim" } })
              require("focal").show(vim.api.nvim_buf_get_name(event.buf))
            end
          end)
        end,
      })
    end,
    config = function(_, opts)
      local focal = require("focal")
      focal.setup(opts)
      focal.register_source({
        filetype = "imagepreview",
        get_path = function() return vim.api.nvim_buf_get_name(0) end,
      })
    end,
  },
}
