# 🇻🇳 Bộ Gõ Tiếng Việt (Fcitx5 Bamboo & Wayland)

Tài liệu này mô tả cấu hình bộ gõ tiếng Việt trên môi trường Wayland, sử dụng framework **Fcitx5** cùng engine **Bamboo**.

---

## 1. Cấu Trúc Module

- **Mã nguồn module:** `modules/fcitx5/`
- **Script cài đặt:** `modules/fcitx5/setup.sh`
- **File cấu hình:** Được symlink vào `~/.config/fcitx5/`:
  - `profile`: Định nghĩa danh sách bàn phím và bộ gõ mặc định (`bamboo`).
  - `config`: Thiết lập phím tắt chuyển đổi (`Ctrl+Space` / `Shift`), giao diện popup ứng viên.
  - `conf/`: Cấu hình chi tiết cho engine Bamboo (kiểu gõ Telex/VNI, bỏ dấu tự do, bảng mã Unicode dựng sẵn).

---

## 2. Gói Phần Mềm Phụ Thuộc (Arch Linux)

Khai báo trong `packages/pacman.txt`:
- `fcitx5`: Framework bộ gõ trung tâm.
- `fcitx5-bamboo`: Engine bộ gõ tiếng Việt chuẩn.
- `fcitx5-gtk`: Module tích hợp cho ứng dụng nền tảng GTK (Chrome, VS Code, Firefox).
- `fcitx5-qt`: Module tích hợp cho ứng dụng nền tảng Qt (Telegram, VLC, VirtualBox).
- `fcitx5-configtool`: Giao diện đồ họa cấu hình Fcitx5.

---

## 3. Biến Môi Trường Wayland & Ozone

Để các ứng dụng Electron / Chromium (Google Chrome, VS Code, Slack, Obsidian) và ứng dụng native Wayland không bị mất dấu, nhảy chữ hoặc lỗi pre-edit, hệ thống cấu hình các biến môi trường tại `~/.config/environment.d/10-fcitx5.conf`:

```ini
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
ELECTRON_OZONE_PLATFORM_HINT=auto
```

### Autostart Daemon
Fcitx5 được cấu hình tự động chạy nền khi người dùng đăng nhập vào desktop thông qua mục `autostart` trong file cấu hình của Umbriel (`~/.config/umbriel/config.toml`):
```toml
[general]
autostart = ["noctalia", "fcitx5 -d"]
```

---

## 4. Kiểm Tra & Khắc Phục Lỗi

```bash
# Kiểm tra trạng thái hoạt động của daemon Fcitx5
fcitx5-diagnose

# Khởi động lại Fcitx5 thủ công nếu cần
pkill fcitx5 && fcitx5 -d
```
