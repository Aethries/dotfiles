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

-- Resize window (Arrow-free modal controls)
map("n", "<leader>w=", "<cmd>wincmd =<CR>", { desc = "Cân bằng kích thước cửa sổ" })
map("n", "<leader>w+", "<cmd>resize +3<CR>", { desc = "Tăng chiều cao cửa sổ" })
map("n", "<leader>w-", "<cmd>resize -3<CR>", { desc = "Giảm chiều cao cửa sổ" })
map("n", "<leader>w<", "<cmd>vertical resize -3<CR>", { desc = "Giảm chiều rộng cửa sổ" })
map("n", "<leader>w>", "<cmd>vertical resize +3<CR>", { desc = "Tăng chiều rộng cửa sổ" })

-- Buffer navigation (Shift + h/l)
map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Buffer trước đó" })
map("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Buffer tiếp theo" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Đóng buffer hiện tại" })

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
