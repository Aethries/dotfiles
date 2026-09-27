# 🪟 Wayland Compositor (Umbriel)

Tài liệu này mô tả cấu hình cho **Umbriel**, Wayland compositor đóng vai trò quản lý cửa sổ và không gian làm việc chính của hệ thống.

---

## 1. Cấu Trúc Module

- **Mã nguồn module:** `modules/umbriel/`
- **Script cài đặt:** `modules/umbriel/setup.sh`
- **File cấu hình:** Được symlink vào `~/.config/umbriel/`:
  - `config.toml`: Cấu hình tổng thể, autostart và file includes.
  - `keybinds.toml`: Bảng phím tắt điều khiển cửa sổ, workspace và ứng dụng.
  - `appearance.toml`: Thiết lập màu sắc, viền và hiệu ứng đồ họa.
  - `noctalia.toml`: Tích hợp với desktop shell Noctalia.

---

## 2. Các Thiết Lập Chính

### A. Cấu Hình Chung (`config.toml`)
- **Mod Key:** Phím `Super` (phím Windows).
- **XWayland:** Bật hỗ trợ chạy ứng dụng X11 (`xwayland = true`).
- **Autostart:**
  - `noctalia`: Tự động khởi chạy desktop shell khi đăng nhập.
  - `fcitx5 -d`: Tự động chạy daemon bộ gõ tiếng Việt Bamboo.
- **Includes:** Tách nhỏ cấu hình thành các file con `appearance.toml`, `keybinds.toml`, `noctalia.toml`.

---

## 3. Bảng Phím Tắt Hệ Thống (`keybinds.toml`)

| Phím tắt | Lệnh / Thao tác | Mô tả |
| :--- | :--- | :--- |
| **`Super + T`** | `spawn:kitty` | Mở GPU terminal Kitty |
| **`Super + B`** | `spawn:google-chrome-stable` | Mở trình duyệt Google Chrome |
| **`Super + Space`** | `spawn:noctalia msg panel-toggle launcher` | Bật/tắt thanh tìm kiếm ứng dụng Noctalia |
| **`Super + D`** | `spawn:noctalia msg panel-toggle launcher` | Phím tắt phụ mở launcher |
| **`Super + Backspace`** | `spawn:systemctl suspend` | Tạm dừng / Suspend máy tính |
| **`Super + Q`** | `window-close` | Đóng cửa sổ đang chọn |
| **`Super + M`** | `window-toggle-maximize` | Phóng to / Thu nhỏ cửa sổ |
| **`Super + H`** | `window-focus-left` | Di chuyển tiêu điểm sang cửa sổ bên trái |
| **`Super + L`** | `window-focus-right` | Di chuyển tiêu điểm sang cửa sổ bên phải |
| **`Super + J`** | `workspace-next` | Chuyển sang không gian làm việc kế tiếp |
| **`Super + K`** | `workspace-previous` | Chuyển về không gian làm việc trước |
| **`Super + Shift + R`** | `config-reload` | Nạp lại cấu hình Umbriel ngay lập tức |

---

## 4. Quản Lý Phiên & Reload

```bash
# Nạp lại cấu hình trực tiếp từ terminal (khi compositor đang chạy)
WAYLAND_DISPLAY=wayland-0 umbriel msg config-reload

# Kiểm tra trạng thái dịch vụ systemd user
systemctl --user status umbriel.service
```
