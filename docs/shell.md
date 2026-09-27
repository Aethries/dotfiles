# 🐚 Môi Trường Dòng Lệnh (Shell & Terminal CLI)

Tài liệu này mô tả cấu hình môi trường dòng lệnh tương tác, bao gồm Zsh, Oh My Zsh, Starship prompt, trình quản lý file Yazi và hệ thống phím tắt/aliases.

---

## 1. Cấu Trúc Module

- **Mã nguồn module:** `modules/shell/`
- **Script cài đặt:** `modules/shell/setup.sh`
- **Thư mục files:**
  - `files/.zshrc`: Cấu hình chính của Zsh shell.
  - `files/starship.toml`: Cấu hình giao diện prompt dòng lệnh.
  - `files/yazi.toml`: Cấu hình trình quản lý file TUI Yazi.

---

## 2. Các Thành Phần Chính

### A. Zsh & Oh My Zsh
- **Framework:** Oh My Zsh đặt tại `~/.oh-my-zsh`.
- **Plugins:**
  - `git`: Hỗ trợ hiển thị và phím tắt git.
  - `zsh-autosuggestions`: Tự động gợi ý câu lệnh dựa trên lịch sử.
  - `zsh-syntax-highlighting`: Đổi màu cú pháp lệnh trực tiếp khi gõ.
- **Lịch sử lệnh (History):** Dung lượng 10,000 dòng, kích hoạt `HIST_IGNORE_DUPS`, `SHARE_HISTORY`, `EXTENDED_HISTORY`.
- **Điều hướng nhanh:** Tích hợp `zoxide` (lệnh `z`) để nhảy tới thư mục thường dùng.
- **FZF Keybindings:** Tự động nạp fzf key bindings và completion từ hệ thống Arch.

### B. Starship Prompt (`starship.toml`)
- Trình tạo prompt nhanh viết bằng Rust, hiển thị trạng thái Git, phiên bản ngôn ngữ (Node, Rust, Go, Python...) và thời gian thực thi.
- Cấu hình tắt dòng trống (`add_newline = false`) để tiết kiệm không gian màn hình.
- Tự động đồng bộ bảng màu Noctalia khi chạy kèm desktop shell.

### C. File Manager Yazi (`yazi.toml`)
- Trình quản lý file TUI siêu tốc viết bằng Rust với async I/O và xem trước hình ảnh.
- **Tích hợp shell:** Hàm wrapper `y()` trong `.zshrc` cho phép tự động đổi thư mục hiện tại của shell theo thư mục làm việc khi thoát Yazi.
- **Mở file nhanh:** Quy tắc `mime` tự động mở file text, JSON, script, YAML, TOML bằng Neovim (`nvim`).

### D. Các Tiện Ích & Aliases Hiện Đại
- `alias c="clear"`
- `alias ls="eza --icons=auto"`
- `alias ll="eza -l --icons=auto"`
- `alias la="eza -la --icons=auto"`
- `alias cat="bat --paging=never"`
- `alias lg="lazygit"`
- `alias ld="lazydocker"`
- Đảm bảo `$HOME/.local/bin` nằm trong `$PATH`.
