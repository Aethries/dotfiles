# ⚙️ Dotfiles

Cấu hình môi trường cá nhân trên **Arch Linux** (Wayland / Umbriel).

---

## 🚀 Quickstart

Cài đặt toàn bộ hệ sinh thái trên máy mới:

```bash
git clone git@github.com:Aethries/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

---

## 📂 Project Structure

```text
.
├── install.sh             # Entrypoint script cài đặt toàn bộ hệ thống
├── packages/              # Package manifests theo từng package manager
├── scripts/               # Shared helper scripts dùng cho bootstrap & quản trị
├── modules/               # Các module cấu hình độc lập (symlink vào $HOME)
└── secrets/               # Thư mục chứa plaintext secrets (chỉ track .gitkeep)
```

---

## 🛠️ Scripts & Package Manifests

### `scripts/`

| File | Chức năng |
| :--- | :--- |
| `common.sh` | Chứa hàm log màu (`log`, `success`, `error`) và helper `command_exists`. |
| `links.sh` | Tạo symbolic link an toàn (`link_file`), tự backup file cũ nếu trùng lặp. |
| `packages.sh` | Cài đặt tự động packages từ `pacman.txt` và `aur.txt`. |
| `secrets.sh` | Mã hóa (`encrypt`) và giải mã (`decrypt`) secrets tĩnh qua `age` + `zstd`. |
| `vault.sh` | Snapshot / restore toàn bộ session apps, browser profiles, SSH keys, credentials. |

### `packages/`

| File | Chức năng |
| :--- | :--- |
| `pacman.txt` | Danh mục package chính thức từ Arch Linux (`core` / `extra`). |
| `aur.txt` | Danh mục package cài từ AUR thông qua `yay`. |
| `node.txt` | Danh mục global npm packages cài qua NVM. |

---

## 🧩 Modules

Mỗi module chứa thư mục `files/` (chứa dotfiles thực tế) và script `setup.sh` (tạo symlink & kích hoạt service).

| Module | Chức năng & File cấu hình chính |
| :--- | :--- |
| **`9router`** | Local AI Gateway. Chứa `systemd` user service, self-signed root CA certificate, DNS override. |
| **`antigravity`** | Cấu hình Antigravity IDE (`settings.json`, `keybindings.json`, snippets). |
| **`fcitx5`** | Bộ gõ tiếng Việt Fcitx5 + Bamboo engine (`profile`, `config`). |
| **`fonts`** | Fontconfig rules (`fonts.conf`) ưu tiên JetBrains Mono Nerd, Inter, Noto. |
| **`greeter`** | Màn hình đăng nhập `greetd` + `noctalia-greeter` session launch. |
| **`kitty`** | GPU-accelerated terminal emulator (`kitty.conf`). |
| **`node`** | Script bootstrap NVM runtime và cài đặt danh sách trong `packages/node.txt`. |
| **`shell`** | Zsh environment (`.zshrc`), Starship prompt (`starship.toml`), Yazi file manager, Cloudflare helper functions. |
| **`umbriel`** | Wayland Compositor (`config.toml`, `keybinds.toml`, window rules). |
| **`vault`** | Chrome password store flags (`chrome-flags.conf`) tích hợp GNOME Keyring. |
| **`zellij`** | Terminal multiplexer (`config.kdl`, default layouts, session switchers). |
