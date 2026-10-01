# Kế hoạch 10: Hệ Sinh Thái Neovim Hiện Đại và Đồng Bộ Theme Tự Động Qua Noctalia

## 1. Tên chức năng
**Xây Dựng Cấu Hình Neovim Hiện Đại Toàn Diện (Lazy.nvim, Mason LSP, Flash.nvim) và Đồng Bộ Hệ Thống Theme Tự Động Qua Noctalia Templates.**

---

## 2. Mô tả chức năng

### 2.1. Vấn đề hiện tại
* Thư mục `modules/nvim` trong bộ dotfiles hiện tại mới chỉ là **khung thư mục rỗng**, hoàn toàn chưa có file Lua cấu hình nào. Người dùng cài đặt Neovim nhưng khi mở lên chỉ có giao diện mặc định thô sơ, chưa có LSP, chưa có auto-completion, format code hay linter.
* Bảng màu giao diện (Theme) hiện đang phân mảnh: Kitty dùng một theme, Zellij dùng theme khác, Neovim và Chrome lại dùng màu khác. Mỗi khi muốn chuyển đổi chế độ sáng/tối (Dark/Light mode), người dùng phải chỉnh sửa thủ công từng file cấu hình riêng biệt.

### 2.2. Mục tiêu kỹ thuật
1. **Xây dựng Module Neovim Chuyên Nghiệp (`modules/nvim/`):**
   * Quản lý plugin hiện đại và tải lười (lazy-loading) bằng **`lazy.nvim`**.
   * Quản lý LSP Server, Formatter, Linter tự động thông qua **`mason.nvim`** và **`mason-lspconfig.nvim`** (hỗ trợ TypeScript, Python, Rust, Go, Lua, Bash, JSON, YAML, TOML, Markdown, Nix).
   * Cú pháp và tô màu ngữ nghĩa siêu tốc bằng **`nvim-treesitter`**.
   * Fuzzy Finder tìm file và tìm kiếm văn bản tốc độ cao bằng **`telescope.nvim`** (hoặc `snacks.nvim`).
   * **Điều hướng Checkpoint 2D với `flash.nvim`:** Nhảy con trỏ tới bất kỳ vị trí nào trên code buffer chỉ với 2 ký tự chữ cái gợi ý (đồng bộ hoàn hảo với trải nghiệm `warpd` trên Desktop và `Vimium C` trên trình duyệt Chrome).
   * Tích hợp Git trực quan với **`gitsigns.nvim`** (xem diff, blame dòng code, revert hunk).
   * Thanh trạng thái tinh gọn: **`lualine.nvim`**.
2. **Hệ Thống Đồng Bộ Theme Tự Động Bằng Noctalia:**
   * Tận dụng engine bảng màu của Noctalia: Tự động trích xuất bảng màu hài hòa từ hình nền đang sử dụng (`noctalia theme`).
   * Sử dụng cơ chế template của Noctalia (`noctalia msg templates-apply`) để tự động render và cập nhật màu sắc đồng nhất sang:
     * Terminal Kitty (`~/.config/kitty/themes/current.conf`).
     * Multiplexer Zellij (`~/.config/zellij/themes/current.kdl`).
     * Editor Neovim và Delta pager.
   * Chuyển đổi Dark Mode / Light Mode toàn hệ thống chỉ bằng một phím tắt hoặc một câu lệnh.

---

## 3. Chi tiết triển khai

### 3.1. Các file cần tạo và sửa đổi

* **[NEW]** `modules/nvim/files/init.lua`: Điểm khởi chạy cấu hình Neovim.
* **[NEW]** `modules/nvim/files/lua/config/lazy.lua`: Bootstrap Lazy.nvim.
* **[NEW]** `modules/nvim/files/lua/config/keymaps.lua`: Bảng phím tắt chuẩn hóa (Leader key là `Space`).
* **[NEW]** `modules/nvim/files/lua/config/options.lua`: Tùy chọn hiển thị (line numbers, tab 4 spaces, clipboard liên kết hệ thống).
* **[NEW]** `modules/nvim/files/lua/plugins/lsp.lua`: Cấu hình Mason, nvim-lspconfig, conform.nvim.
* **[NEW]** `modules/nvim/files/lua/plugins/treesitter.lua`: Cấu hình Treesitter.
* **[NEW]** `modules/nvim/files/lua/plugins/navigation.lua`: Cấu hình Telescope và `flash.nvim`.
* **[NEW]** `modules/nvim/files/lua/plugins/ui.lua`: Cấu hình Lualine, Gitsigns, Catppuccin/Noctalia theme.
* **[NEW]** `modules/nvim/setup.sh`: Script symlink cấu hình vào `~/.config/nvim`.
* **[NEW]** `modules/noctalia/files/templates/`: Các file mẫu màu cho Kitty và Zellij.
* **[MODIFY]** [install.sh](file:///home/loc/Workspaces/dotfiles/install.sh): Thêm lệnh thực thi `modules/nvim/setup.sh`.

### 3.2. Cấu hình điều hướng Checkpoint: `modules/nvim/files/lua/plugins/navigation.lua`

```lua
return {
  -- Flash.nvim: Checkpoint Hint Navigation trên code buffer
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash Jump" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    },
  },

  -- Telescope: Fuzzy Finder
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Tìm file" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Tìm nội dung (Grep)" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Xem danh sách buffer" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Tra cứu trợ giúp" },
    },
  },
}
```

---

## 4. Hướng dẫn sử dụng

### 4.1. Bảng phím tắt thao tác nhanh trong Neovim (Leader = `Space`)

| Phím tắt | Tác vụ | Mô tả chi tiết |
|---|---|---|
| `s` + `2 ký tự` | **Flash Jump** | Nhảy con trỏ tức thì tới bất kỳ từ nào trên màn hình |
| `Space + f + f` | Tìm File | Mở popup tìm kiếm tên file siêu tốc qua Telescope |
| `Space + f + g` | Live Grep | Tìm kiếm chuỗi văn bản xuyên suốt toàn bộ repository |
| `Space + c + f` | Format Code | Định dạng lại file code hiện tại qua LSP / Formatter |
| `Space + c + a` | Code Action | Hiện gợi ý sửa lỗi nhanh (Quick Fix, Import) |
| `Space + e` | File Explorer | Bật/tắt thanh duyệt cây thư mục |
| `gd` | Go to Definition | Nhảy thẳng tới định nghĩa của hàm / biến |
| `K` | Hover Doc | Xem tài liệu mô tả và kiểu dữ liệu của hàm / class |

### 4.2. Đồng bộ Theme Toàn Hệ Thống

```bash
# 1. Chuyển đổi Dark Mode <-> Light Mode toàn bộ hệ thống
noctalia msg theme-mode-toggle
# Desktop bar, Terminal Kitty, Zellij và Neovim sẽ tự động chuyển màu đồng bộ

# 2. Đặt hình nền mới và tự động cập nhật bảng màu hài hòa cho toàn bộ app
noctalia theme /path/to/my-wallpaper.jpg
noctalia msg templates-apply
```

---

## 5. Tiêu chuẩn kiểm thử & Nghiệm thu (Verification)

1. **Kiểm tra khởi động Neovim:**
   ```bash
   nvim --headless "+Lazy! sync" +qa
   # Lazy.nvim phải tải và cài đặt toàn bộ plugin mà không có lỗi Lua nào
   ```
2. **Kiểm tra Mason LSP:**
   * Mở một file TypeScript (`test.ts`) hoặc Rust (`main.rs`).
   * Chạy `:LspInfo`: LSP Server tương ứng (ts_ls hoặc rust_analyzer) phải ở trạng thái attached.
3. **Kiểm tra tính năng Flash Jump:**
   * Mở một file code dài bất kỳ.
   * Bấm `s` + gõ 2 ký tự: Toàn bộ các vị trí trùng khớp trên màn hình hiện các checkpoint chữ cái rõ ràng.
