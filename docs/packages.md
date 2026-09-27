# 📦 Quản Lý Gói Phần Mềm (Packages Catalog)

Tài liệu này mô tả cách thức tổ chức, phân loại và quản lý các gói phần mềm trên hệ thống Arch Linux thông qua Pacman, AUR (yay) và NPM (Node.js).

---

## 1. Cơ Chế Quản Lý

Thay vì viết cứng danh sách package vào code cài đặt, hệ thống tách rời thành các file văn bản phẳng đặt trong thư mục `packages/`:

| File | Trình quản lý | Nguồn cài đặt | Vai trò |
| :--- | :--- | :--- | :--- |
| **`packages/pacman.txt`** | `pacman` | Kho chính thức của Arch Linux | Các công cụ hệ thống, terminal, dev tools, font chữ |
| **`packages/aur.txt`** | `yay` | Arch User Repository (AUR) | Các ứng dụng desktop, theme, package đóng gói cộng đồng |
| **`packages/node.txt`** | `npm` (NVM) | Node Package Manager | Các công cụ CLI chạy trên nền tảng Node.js (global) |

Script `scripts/packages.sh` sẽ tự động đọc danh sách, loại bỏ các dòng comment `#` và dòng trống, sau đó thực thi lệnh cài đặt với cờ `--needed --noconfirm`.

---

## 2. Danh Mục Các Gói Cụ Thể

### A. Packages Chính Thức (`packages/pacman.txt`)
- **Hệ thống cơ bản:** `git`, `curl`, `wget`, `unzip`, `zip`, `7zip`, `tar`, `rsync`, `openssh`, `age`, `sqlite`.
- **Terminal & Hiển thị:** `kitty`, `neovim`, `zellij`, `zsh`, `fzf`, `ripgrep`, `fd`, `jq`, `yq`, `yazi`, `starship`, `zoxide`.
- **Tiện ích CLI hiện đại:** `eza`, `bat`, `bottom`, `lazygit`, `lazydocker`, `trash-cli`, `tealdeer`, `dust`, `duf`, `gping`, `tokei`.
- **Môi trường phát triển:** `base-devel`, `gcc`, `make`, `cmake`, `pkgconf`, `nvm`.
- **Môi trường Desktop & Audio:** `greetd`, `wl-clipboard`, `pipewire`, `pipewire-audio`, `pipewire-pulse`, `wireplumber`, `networkmanager`.
- **Bộ gõ tiếng Việt:** `fcitx5`, `fcitx5-bamboo`, `fcitx5-gtk`, `fcitx5-qt`, `fcitx5-configtool`.
- **Bộ font chữ:** `ttf-jetbrains-mono-nerd`, `noto-fonts`, `noto-fonts-cjk`, `noto-fonts-emoji`.

### B. Packages AUR (`packages/aur.txt`)
- **Ứng dụng Desktop & Trao đổi:** `google-chrome`, `telegram-desktop`, `slack-desktop`, `larksuite-bin`, `obsidian`, `postman-bin`, `beekeeper-studio-bin`, `docker`.
- **Giao diện & Compositor:** `umbriel-git`, `noctalia-greeter`.
- **Công cụ AI:** `antigravity`, `antigravity-ide`, `antigravity-cli`.

### C. Packages NPM Global (`packages/node.txt`)
- `9router`: MITM proxy gateway cho AI Coding Agents.

---

## 3. Cách Bổ Sung Package Mới

1. Mở file tương ứng trong `packages/` (`pacman.txt`, `aur.txt`, hoặc `node.txt`).
2. Thêm tên gói vào cuối file (có thể chú thích bằng `#`).
3. Chạy lệnh cài đặt để hệ thống tự động tải và cài gói mới:
   ```bash
   ./scripts/packages.sh
   ```
