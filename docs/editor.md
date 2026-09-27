# 📝 Trình Soạn Thảo Mã Nguồn (Neovim Lua IDE)

Tài liệu này mô tả cấu hình cho **Neovim**, môi trường lập trình (IDE) dòng lệnh hoàn chỉnh được viết hoàn toàn bằng ngôn ngữ Lua.

---

## 1. Cấu Trúc Module

- **Mã nguồn module:** `modules/nvim/`
- **Script cài đặt:** `modules/nvim/setup.sh`
- **File cấu hình:** Được symlink vào `~/.config/nvim/`:
  - `init.lua`: Điểm khởi nhập chính của Neovim.
  - `lua/`: Các module Lua chuyên biệt (cấu hình core, plugins, keymaps, options).
  - `lazy-lock.json`: File khóa cố định phiên bản commit chính xác của mọi plugin.
  - `after/`: Cấu hình nạp sau (ftplugin, syntax overrides).
  - `keymaps/`: Danh sách các phím tắt chuyên biệt.

---

## 2. Các Tính Năng Nổi Bật

### A. Quản Lý Plugin Với `lazy.nvim`
- Tải plugin lười (lazy loading) giúp Neovim khởi động tức thì dưới 50ms.
- Toàn bộ trạng thái plugin được ghim chặt chẽ qua file `lazy-lock.json`, đảm bảo khi cài lại máy không bao giờ gặp lỗi phá vỡ tương thích (breaking changes).

### B. Ngôn Ngữ & Trí Tuệ Nhân Tạo (LSP & Treesitter)
- **Treesitter:** Phân tích cú pháp AST nâng cao, làm nổi bật màu sắc chính xác theo ngữ cảnh ngữ nghĩa của mã nguồn.
- **Language Server Protocol (LSP):**
  - Tự động hoàn thành code (Auto-completion).
  - Gợi ý lỗi trực tiếp (Diagnostics & Inlay hints).
  - Định dạng mã nguồn (Format on save) qua Conform / LSP.
  - Hỗ trợ đa ngôn ngữ: TypeScript/JavaScript, Python, Rust, Go, Lua, Bash, JSON, YAML, TOML, Markdown.

### C. Tìm Kiếm & Điều Hướng
- Tích hợp tìm kiếm nhanh file, chuỗi văn bản (`ripgrep`), git commits qua Telescope hoặc Snacks Picker.
- Tích hợp điều hướng liền mạch với Zellij qua `vim-zellij-navigator` (`Ctrl + h/j/k/l`).

---

## 3. Lệnh Vận Hành Thường Dùng

```bash
# Mở Neovim
nvim [duong-dan-file]

# Trong Neovim: Quản lý plugin
:Lazy

# Kiểm tra trạng thái sức khỏe của Neovim và LSP
:checkhealth

# Cập nhật hoặc đồng bộ lại plugins theo lockfile
:Lazy sync
```
