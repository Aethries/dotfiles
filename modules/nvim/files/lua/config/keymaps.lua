-- ==============================================================================
-- Neovim Keymaps (Leader = Space)
-- ==============================================================================

local map = vim.keymap.set

-- Quick escape in insert mode
map("i", "jk", "<ESC>", { desc = "Thoát Insert mode nhanh" })

-- Clear search highlights
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Xóa highlight tìm kiếm" })

-- Window navigation: seamless Neovim/Zellij handled in lua/plugins/navigation.lua (<C-h/j/k/l>)

-- Disable arrow keys across all modes (enforce hjkl home-row navigation)
for _, key in ipairs({ "<Up>", "<Down>", "<Left>", "<Right>" }) do
  map({ "n", "i", "v", "x" }, key, "<nop>", { desc = "Phím mũi tên bị vô hiệu hóa" })
end

-- ==============================================================================
-- Window & Pane Management (Resize, Split, Maximize & Submode)
-- ==============================================================================

-- 1. Direct Instant Resizing (Hold Ctrl+Alt or Ctrl+Arrows and tap to resize)
map("n", "<C-M-h>", "<cmd>vertical resize -4<CR>", { desc = "Giảm chiều rộng pane (Ctrl+Alt+h)" })
map("n", "<C-M-l>", "<cmd>vertical resize +4<CR>", { desc = "Tăng chiều rộng pane (Ctrl+Alt+l)" })
map("n", "<C-M-j>", "<cmd>resize -4<CR>", { desc = "Giảm chiều cao pane (Ctrl+Alt+j)" })
map("n", "<C-M-k>", "<cmd>resize +4<CR>", { desc = "Tăng chiều cao pane (Ctrl+Alt+k)" })

map("n", "<C-Left>", "<cmd>vertical resize -4<CR>", { desc = "Giảm chiều rộng pane (Ctrl+Left)" })
map("n", "<C-Right>", "<cmd>vertical resize +4<CR>", { desc = "Tăng chiều rộng pane (Ctrl+Right)" })
map("n", "<C-Down>", "<cmd>resize -4<CR>", { desc = "Giảm chiều cao pane (Ctrl+Down)" })
map("n", "<C-Up>", "<cmd>resize +4<CR>", { desc = "Tăng chiều cao pane (Ctrl+Up)" })

-- 2. Leader Window Controls (<leader>w)
map("n", "<leader>wh", "<cmd>vertical resize -4<CR>", { desc = "Giảm chiều rộng pane (-4)" })
map("n", "<leader>wl", "<cmd>vertical resize +4<CR>", { desc = "Tăng chiều rộng pane (+4)" })
map("n", "<leader>wj", "<cmd>resize -4<CR>", { desc = "Giảm chiều cao pane (-4)" })
map("n", "<leader>wk", "<cmd>resize +4<CR>", { desc = "Tăng chiều cao pane (+4)" })
map("n", "<leader>w=", "<cmd>wincmd =<CR>", { desc = "Cân bằng kích thước tất cả pane" })
map("n", "<leader>wv", "<cmd>vsplit<CR>", { desc = "Tách cửa sổ dọc (Vertical Split)" })
map("n", "<leader>wx", "<cmd>close<CR>", { desc = "Đóng pane hiện tại" })

-- Maximize / Restore current pane
local is_maximized = false
map("n", "<leader>wm", function()
  if is_maximized then
    vim.cmd("wincmd =")
    is_maximized = false
  else
    vim.cmd("wincmd |")
    vim.cmd("wincmd _")
    is_maximized = true
  end
end, { desc = "Phóng to / Khôi phục kích thước pane (Maximize)" })

-- Interactive Resize Submode (spam h/j/k/l freely without pressing leader each time)
map("n", "<leader>wr", function()
  local info = {
    { " 󰩨 [RESIZE SUBMODE] ", "FloatTitle" },
    { " h: ◄ | l: ► | j: ▼ | k: ▲ | =: Balance | m: Maximize | <Esc>: Exit", "DiagnosticInfo" },
  }
  vim.api.nvim_echo(info, false, {})
  while true do
    local ok, char = pcall(vim.fn.getcharstr)
    if not ok or char == "\27" or char == "\r" or char == "q" or char == " " then
      vim.api.nvim_echo({}, false, {})
      break
    elseif char == "h" then
      vim.cmd("vertical resize -4")
      vim.api.nvim_echo(info, false, {})
    elseif char == "l" then
      vim.cmd("vertical resize +4")
      vim.api.nvim_echo(info, false, {})
    elseif char == "j" then
      vim.cmd("resize -4")
      vim.api.nvim_echo(info, false, {})
    elseif char == "k" then
      vim.cmd("resize +4")
      vim.api.nvim_echo(info, false, {})
    elseif char == "=" then
      vim.cmd("wincmd =")
      vim.api.nvim_echo(info, false, {})
    elseif char == "m" then
      vim.cmd("wincmd |")
      vim.cmd("wincmd _")
      vim.api.nvim_echo(info, false, {})
    else
      vim.api.nvim_echo({}, false, {})
      break
    end
  end
end, { desc = "Vào chế độ chỉnh kích thước tương tác (Resize Submode)" })

-- 3. Tab Management
map("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Mở Tab mới" })
map("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Đóng Tab hiện tại" })
map("n", "<leader>tn", "<cmd>tabnext<CR>", { desc = "Tab tiếp theo" })
map("n", "<leader>tp", "<cmd>tabprevious<CR>", { desc = "Tab trước đó" })

-- 4. Buffer navigation (Shift + h/l)
map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Buffer trước đó" })
map("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Buffer tiếp theo" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Đóng buffer hiện tại" })
map("n", "<leader>bo", "<cmd>%bd|e#|bd#<CR>", { desc = "Đóng tất cả buffer khác" })

-- Save & Quit
map("n", "<leader>w", "<cmd>w<CR>", { desc = "Lưu file" })
map("n", "<leader>q", "<cmd>q<CR>", { desc = "Đóng cửa sổ" })

-- Stay in indent mode when indenting in visual mode
map("v", "<", "<gv", { desc = "Thụt lề trái và giữ vùng chọn" })
map("v", ">", ">gv", { desc = "Thụt lề phải và giữ vùng chọn" })

-- Move text up and down in visual mode
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Di chuyển khối code xuống dưới" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Di chuyển khối code lên trên" })

-- Better paste: do not replace clipboard register on paste in visual mode
map("x", "p", [["_dP]], { desc = "Dán không ghi đè clipboard register" })

-- Interactive Cheatsheet (English & Vietnamese)
map("n", "<leader>?", function() require("config.cheatsheet").show() end, { desc = "Bảng tra cứu phím tắt (Cheatsheet)" })
map("n", "<leader>ch", function() require("config.cheatsheet").show() end, { desc = "Bảng tra cứu phím tắt (Cheatsheet)" })
map("n", "<F1>", function() require("config.cheatsheet").show() end, { desc = "Bảng tra cứu phím tắt (Cheatsheet)" })

-- Register global user command
vim.api.nvim_create_user_command("Cheatsheet", function()
  require("config.cheatsheet").show()
end, { desc = "Bảng tra cứu phím tắt tương tác (Cheatsheet EN/VI)" })
