-- ==============================================================================
-- Bilingual Interactive Cheatsheet (English & Tiếng Việt) for Telescope
-- Searchable by keybinds, categories, or functional descriptions
-- ==============================================================================

local M = {}

M.items = {
  -- General & Editing
  { key = "<leader>w", cat = "General", en = "Save file", vi = "Lưu file", action = "w" },
  { key = "<leader>q", cat = "General", en = "Close window", vi = "Đóng cửa sổ", action = "q" },
  { key = "<Esc>", cat = "General", en = "Clear search highlight", vi = "Xóa highlight tìm kiếm", action = "nohlsearch" },
  { key = "jk", cat = "General", en = "Escape insert mode", vi = "Thoát Insert mode nhanh" },
  { key = "<leader>bd", cat = "Buffer", en = "Close current buffer", vi = "Đóng buffer hiện tại", action = "bdelete" },
  { key = "<S-h>", cat = "Buffer", en = "Previous buffer", vi = "Buffer trước đó", action = "bprevious" },
  { key = "<S-l>", cat = "Buffer", en = "Next buffer", vi = "Buffer tiếp theo", action = "bnext" },
  { key = "< / >", cat = "Visual", en = "Indent left/right (keep selection)", vi = "Thụt lề trái/phải (giữ vùng chọn)" },
  { key = "J / K", cat = "Visual", en = "Move selected block down/up", vi = "Di chuyển khối code xuống/lên" },
  { key = "p", cat = "Visual", en = "Paste without overwriting clipboard register", vi = "Dán không ghi đè clipboard register" },

  -- Window Navigation & Resizing (Zellij + Neovim)
  { key = "<C-h>", cat = "Window", en = "Move split left or Zellij pane left", vi = "Chuyển split hoặc pane Zellij sang trái", action = "ZellijNavigateLeftTab" },
  { key = "<C-j>", cat = "Window", en = "Move split down or Zellij pane down", vi = "Chuyển split hoặc pane Zellij xuống dưới", action = "ZellijNavigateDown" },
  { key = "<C-k>", cat = "Window", en = "Move split up or Zellij pane up", vi = "Chuyển split hoặc pane Zellij lên trên", action = "ZellijNavigateUp" },
  { key = "<C-l>", cat = "Window", en = "Move split right or Zellij pane right", vi = "Chuyển split hoặc pane Zellij sang phải", action = "ZellijNavigateRightTab" },
  { key = "<leader>w=", cat = "Window", en = "Equalize window sizes", vi = "Cân bằng kích thước tất cả cửa sổ", action = "wincmd =" },
  { key = "<leader>w+", cat = "Window", en = "Increase window height (+3)", vi = "Tăng chiều cao cửa sổ (+3)", action = "resize +3" },
  { key = "<leader>w-", cat = "Window", en = "Decrease window height (-3)", vi = "Giảm chiều cao cửa sổ (-3)", action = "resize -3" },
  { key = "<leader>w<", cat = "Window", en = "Decrease window width (-3)", vi = "Giảm chiều rộng cửa sổ (-3)", action = "vertical resize -3" },
  { key = "<leader>w>", cat = "Window", en = "Increase window width (+3)", vi = "Tăng chiều rộng cửa sổ (+3)", action = "vertical resize +3" },

  -- Motions & Navigation
  { key = "w", cat = "Motion", en = "Subword forward (camelCase/snake_case/kebab-case)", vi = "Nhảy từ con tiến tới (hỗ trợ camel/snake/kebab)" },
  { key = "e", cat = "Motion", en = "Subword end (camelCase/snake_case/kebab-case)", vi = "Nhảy đến cuối từ con" },
  { key = "b", cat = "Motion", en = "Subword backward (camelCase/snake_case/kebab-case)", vi = "Nhảy từ con lùi lại" },
  { key = "ge", cat = "Motion", en = "Subword backward end", vi = "Nhảy lùi đến cuối từ con" },
  { key = "s", cat = "Motion", en = "Flash 2D jump anywhere on screen", vi = "Nhảy 2D nhanh tới ký tự bất kỳ trên màn hình (Flash)" },
  { key = "S", cat = "Motion", en = "Flash Treesitter syntax node select", vi = "Nhảy và chọn khối cú pháp Treesitter (Flash)" },
  { key = "<leader>e", cat = "Explorer", en = "Toggle file explorer tree", vi = "Bật/Tắt cây thư mục (NvimTree)", action = "NvimTreeToggle" },

  -- Telescope Fuzzy Search
  { key = "<leader>ff", cat = "Telescope", en = "Find files by filename", vi = "Tìm kiếm file theo tên", action = "Telescope find_files" },
  { key = "<leader>fg", cat = "Telescope", en = "Live grep text in project", vi = "Tìm kiếm nội dung (Grep) trong project", action = "Telescope live_grep" },
  { key = "<leader>fb", cat = "Telescope", en = "List and switch open buffers", vi = "Xem danh sách và chuyển buffer đang mở", action = "Telescope buffers" },
  { key = "<leader>fr", cat = "Telescope", en = "Search recently opened files", vi = "Tìm danh sách file đã mở gần đây", action = "Telescope oldfiles" },
  { key = "<leader>fs", cat = "Telescope", en = "Search Git status modified files", vi = "Tìm file thay đổi trong Git Status", action = "Telescope git_status" },
  { key = "<leader>fh", cat = "Telescope", en = "Search help documentation tags", vi = "Tra cứu tài liệu trợ giúp Neovim", action = "Telescope help_tags" },
  { key = "<leader>?", cat = "Telescope", en = "Interactive cheatsheet (EN / VI)", vi = "Bảng tra cứu phím tắt Anh - Việt tương tác" },

  -- LSP & Code Intelligence
  { key = "gd", cat = "LSP", en = "Go to symbol definition", vi = "Đi đến nơi định nghĩa hàm/biến", action = "lua vim.lsp.buf.definition()" },
  { key = "gr", cat = "LSP", en = "Find all references", vi = "Tìm tất cả tham chiếu của symbol", action = "lua vim.lsp.buf.references()" },
  { key = "K", cat = "LSP", en = "Hover documentation / type info", vi = "Xem tài liệu kiểu dữ liệu hàm/biến", action = "lua vim.lsp.buf.hover()" },
  { key = "<leader>ca", cat = "LSP", en = "Code actions / quick fixes", vi = "Thực hiện gợi ý sửa lỗi (Code Action)", action = "lua vim.lsp.buf.code_action()" },
  { key = "<leader>cr", cat = "LSP", en = "Rename symbol project-wide", vi = "Đổi tên biến/hàm trên toàn project", action = "lua vim.lsp.buf.rename()" },
  { key = "<leader>cd", cat = "LSP", en = "Show line diagnostic float", vi = "Xem chi tiết lỗi dòng hiện tại", action = "lua vim.diagnostic.open_float()" },
  { key = "[d / ]d", cat = "LSP", en = "Jump to previous / next diagnostic", vi = "Nhảy tới lỗi cảnh báo trước / tiếp theo" },
  { key = "<leader>cf", cat = "LSP", en = "Format code buffer (Conform)", vi = "Định dạng mã nguồn (Conform)", action = "lua require('conform').format({ lsp_fallback = true })" },
  { key = "<C-Space>", cat = "LSP", en = "Trigger autocompletion menu", vi = "Kích hoạt popup menu gợi ý autocomplete" },
  { key = "<CR>", cat = "LSP", en = "Confirm selected completion", vi = "Xác nhận chọn gợi ý autocomplete" },

  -- Git Hunks
  { key = "]c / [c", cat = "Git", en = "Jump to next / previous git change hunk", vi = "Nhảy tới đoạn code git thay đổi tiếp / trước" },
  { key = "<leader>hs", cat = "Git", en = "Stage current git hunk", vi = "Stage đoạn code thay đổi hiện tại", action = "Gitsigns stage_hunk" },
  { key = "<leader>hr", cat = "Git", en = "Reset / discard current git hunk", vi = "Hoàn tác / hủy bỏ đoạn code thay đổi hiện tại", action = "Gitsigns reset_hunk" },
  { key = "<leader>hp", cat = "Git", en = "Preview current git hunk diff", vi = "Xem trước khác biệt của đoạn code git", action = "Gitsigns preview_hunk" },
}

function M.show(opts)
  opts = opts or {}
  local ok, pickers = pcall(require, "telescope.pickers")
  if not ok then
    vim.notify("Telescope is required for Cheatsheet", vim.log.levels.ERROR)
    return
  end

  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local entry_display = require("telescope.pickers.entry_display")

  local displayer = entry_display.create({
    separator = " │ ",
    items = {
      { width = 14 },
      { width = 11 },
      { remaining = true },
    },
  })

  local make_display = function(entry)
    local item = entry.value
    return displayer({
      { item.key, "TelescopeResultsIdentifier" },
      { "[" .. item.cat .. "]", "TelescopeResultsComment" },
      { item.en .. "  •  " .. item.vi },
    })
  end

  pickers.new(opts, {
    prompt_title = "Cheatsheet (English & Tiếng Việt)",
    finder = finders.new_table({
      results = M.items,
      entry_maker = function(item)
        local search_str = string.format("%s %s %s %s", item.key, item.cat, item.en, item.vi)
        return {
          value = item,
          display = make_display,
          ordinal = search_str,
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection and selection.value and selection.value.action then
          pcall(vim.cmd, selection.value.action)
        end
      end)
      return true
    end,
  }):find()
end

-- Register user command
vim.api.nvim_create_user_command("Cheatsheet", function()
  M.show()
end, { desc = "Show interactive bilingual cheatsheet" })

return M
