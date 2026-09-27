# 📚 Tài Liệu Kỹ Thuật Dự Án Dotfiles

Chào mừng bạn đến với tài liệu hướng dẫn kỹ thuật của hệ thống **Dotfiles trên Arch Linux**. Thư mục này lưu trữ tài liệu phân tích chi tiết cho từng tính năng và phân hệ của dự án.

---

## 📑 Danh Mục Tính Năng (Feature Docs)

| Tính năng / Phân hệ | Tài liệu chi tiết | Mô tả tóm tắt |
| :--- | :--- | :--- |
| **Bảo Mật & Phiên Làm Việc** | [docs/secrets-vault.md](file:///home/loc/Workspaces/dotfiles/docs/secrets-vault.md) | Hệ thống mã hóa secrets repo và đồng bộ phiên làm việc Zero-Knowledge. |
| **Môi Trường Dòng Lệnh** | [docs/shell.md](file:///home/loc/Workspaces/dotfiles/docs/shell.md) | Cấu hình Zsh, Oh My Zsh, Starship prompt và Yazi file manager. |
| **Wayland Compositor** | [docs/window-manager.md](file:///home/loc/Workspaces/dotfiles/docs/window-manager.md) | Trình quản lý cửa sổ Umbriel, bảng phím tắt `keybinds.toml` và nạp lại cấu hình. |
| **Desktop Shell & Đăng Nhập** | [docs/desktop-shell.md](file:///home/loc/Workspaces/dotfiles/docs/desktop-shell.md) | Desktop shell Noctalia, thanh panel, launcher và màn hình đăng nhập greetd. |
| **Bộ Gõ Tiếng Việt** | [docs/input-method.md](file:///home/loc/Workspaces/dotfiles/docs/input-method.md) | Bộ gõ Fcitx5 Bamboo, cấu hình Wayland Ozone chống lỗi nhảy chữ. |
| **Trình Giả Lập Terminal** | [docs/terminal.md](file:///home/loc/Workspaces/dotfiles/docs/terminal.md) | Cấu hình Kitty tăng tốc GPU, phông chữ JetBrains Mono Nerd và kho themes. |
| **Multiplexer Dòng Lệnh** | [docs/multiplexer.md](file:///home/loc/Workspaces/dotfiles/docs/multiplexer.md) | Quản lý phiên làm việc Zellij, layouts và các WASM plugins ghim sẵn. |
| **Trình Soạn Thảo Mã Nguồn** | [docs/editor.md](file:///home/loc/Workspaces/dotfiles/docs/editor.md) | Neovim Lua IDE hoàn chỉnh với LSP, Treesitter, Snacks, lazy-lock. |
| **Workflow & Tiện Ích CLI** | [docs/workflow.md](file:///home/loc/Workspaces/dotfiles/docs/workflow.md) | Chuyển đổi project siêu tốc `pj`, cấu hình Git và bộ công cụ dòng lệnh hiện đại. |
| **Hạ Tầng AI & Agent Skills** | [docs/ai.md](file:///home/loc/Workspaces/dotfiles/docs/ai.md) | Proxy 9Router, Root CA, DNS loopback và kho 80+ kỹ năng AI agent. |
| **Quản Lý Gói Phần Mềm** | [docs/packages.md](file:///home/loc/Workspaces/dotfiles/docs/packages.md) | Danh mục quản lý gói phần mềm Pacman, AUR (yay) và NPM (Node.js). |

---

## 🏗️ Cấu Trúc Mã Nguồn

```text
dotfiles/
├── install.sh                  # Bootstrap tổng thể hệ thống
├── docs/                       # Tài liệu kỹ thuật chi tiết từng tính năng
├── packages/                   # Danh sách gói phần mềm (pacman.txt, aur.txt, node.txt)
├── scripts/                    # Scripts tiện ích hệ thống (links, packages, common)
└── modules/                    # Các module cấu hình độc lập (shell, umbriel, greeter, node...)
```
