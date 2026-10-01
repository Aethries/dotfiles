# Kế hoạch 01: Khôi phục Noctalia Desktop Shell và Hoàn thiện Umbriel Compositor

## 1. Tên chức năng
**Khôi phục và Đồng bộ Hóa Desktop Shell Noctalia với Umbriel Compositor.**

---

## 2. Mô tả chức năng

### 2.1. Vấn đề hiện tại
* Gói `noctalia` đang cài đặt trên máy và đang chạy autostart cùng `umbriel`, nhưng trong repo dotfiles thư mục `modules/noctalia` đã bị xóa trước đây.
* Hệ quả là đường dẫn `~/.config/noctalia/config.toml` trên máy hiện tại đang là một **broken symlink** chỉ vào đường dẫn không tồn tại.
* Trong danh sách package [packages/aur.txt](file:///home/loc/Workspaces/dotfiles/packages/aur.txt), chỉ có `noctalia-greeter`, thiếu package chính `noctalia`. Nếu cài đặt lại trên máy mới sẽ bị thiếu shell giao diện.
* [modules/umbriel/files/config.toml](file:///home/loc/Workspaces/dotfiles/modules/umbriel/files/config.toml) và [modules/umbriel/files/keybinds.toml](file:///home/loc/Workspaces/dotfiles/modules/umbriel/files/keybinds.toml) mới chỉ có cấu hình cơ bản, chưa khai thác hết các panel và lệnh điều khiển nhanh của Noctalia (như Notification center, Do Not Disturb, screenshot annotation, OSD, wallpaper).

### 2.2. Mục tiêu kỹ thuật
1. Bổ sung `noctalia` vào `packages/aur.txt`.
2. Tạo lại module `modules/noctalia/` với cấu trúc chuẩn:
   * `modules/noctalia/setup.sh`: Quản lý symlink `~/.config/noctalia/config.toml` và các plugin liên quan.
   * `modules/noctalia/files/config.toml`: Quản lý bar, widgets, notification center, OSD, launcher và theme engine.
3. Cập nhật `install.sh` để tự động chạy `modules/noctalia/setup.sh`.
4. Hoàn thiện `modules/umbriel/`:
   * Bổ sung window rules cho các cửa sổ nổi (floating dialogs, file chooser, picture-in-picture).
   * Mở rộng `keybinds.toml` để liên kết chặt chẽ với các lệnh `noctalia msg`.

---

## 3. Chi tiết triển khai

### 3.1. Các file cần tạo và sửa đổi

* **[MODIFY]** [packages/aur.txt](file:///home/loc/Workspaces/dotfiles/packages/aur.txt): Bổ sung `noctalia`.
* **[NEW]** `modules/noctalia/files/config.toml`: File cấu hình giao diện Noctalia shell.
* **[NEW]** `modules/noctalia/setup.sh`: Script liên kết symlink cấu hình và khởi động lại shell nếu cần.
* **[MODIFY]** [modules/umbriel/files/config.toml](file:///home/loc/Workspaces/dotfiles/modules/umbriel/files/config.toml): Thêm window rules cho floating window và tỷ lệ hiển thị.
* **[MODIFY]** [modules/umbriel/files/keybinds.toml](file:///home/loc/Workspaces/dotfiles/modules/umbriel/files/keybinds.toml): Thêm phím tắt gọi notification center, DND, OSD volume/mic, screenshot annotation.
* **[MODIFY]** [install.sh](file:///home/loc/Workspaces/dotfiles/install.sh): Thêm dòng `bash "$DOTFILES/modules/noctalia/setup.sh"`.

### 3.2. Cấu hình mẫu cho Keybindings trong Umbriel

```toml
# Gắn phím tắt điều khiển Noctalia trong modules/umbriel/files/keybinds.toml
"Mod+Space" = "spawn:noctalia msg panel-toggle launcher"
"Mod+N" = "spawn:noctalia msg panel-toggle notifications"
"Mod+Shift+N" = "spawn:noctalia msg notification-dnd-toggle"
"Mod+BackSpace" = "spawn:noctalia msg session lock"

# Screenshot & Annotation tức thì qua Noctalia
"Print" = "spawn:noctalia msg screenshot-fullscreen"
"Mod+Print" = "spawn:noctalia msg screenshot-region"
"Mod+Shift+S" = "spawn:noctalia msg screenshot-annotate"

# Audio & Media OSD
"XF86AudioRaiseVolume" = "spawn:noctalia msg volume-up"
"XF86AudioLowerVolume" = "spawn:noctalia msg volume-down"
"XF86AudioMute" = "spawn:noctalia msg volume-mute"
"XF86AudioMicMute" = "spawn:noctalia msg mic-mute"
"XF86AudioPlay" = "spawn:noctalia msg media play-pause"
"XF86AudioNext" = "spawn:noctalia msg media next"
"XF86AudioPrev" = "spawn:noctalia msg media previous"
```

---

## 4. Hướng dẫn sử dụng

### 4.1. Bảng phím tắt hằng ngày

| Phím tắt | Tác vụ | Mô tả hành vi |
|---|---|---|
| `Mod + Space` | Mở Launcher | Mở thanh tìm kiếm ứng dụng và lệnh hệ thống |
| `Mod + N` | Mở Notification Center | Xem lại toàn bộ thông báo đã nhận, xóa thông báo cũ |
| `Mod + Shift + N` | Bật/Tắt Do Not Disturb (DND) | Ẩn tạm thời các popup thông báo khi cần tập trung code |
| `Mod + Shift + S` | Đóng băng & Chú thích màn hình | Đóng băng màn hình tức thì, cho phép vẽ mũi tên, khung viền, che thông tin nhạy cảm trước khi copy |
| `Mod + BackSpace` | Khóa màn hình | Kích hoạt Noctalia session lock |
| `Phím âm lượng / mic` | Điều khiển âm thanh | Tăng/giảm âm lượng, mute mic và hiện OSD trực quan |

### 4.2. Các lệnh dòng lệnh CLI hữu ích với `noctalia msg`

```bash
# Đổi chế độ sáng / tối toàn desktop
noctalia msg theme-mode-toggle

# Đặt hình nền mới và tự động sinh bảng màu
noctalia msg wallpaper-set /path/to/wallpaper.jpg

# Chuyển đổi profile năng lượng (Performance, Balanced, Power-saver)
noctalia msg power-cycle

# Hiển thị thông báo kiểm tra hệ thống
noctalia msg notification-show "Hệ thống" "Đã nạp lại cấu hình dotfiles thành công"
```

---

## 5. Tiêu chuẩn kiểm thử & Nghiệm thu (Verification)

1. **Kiểm tra Symlink:**
   ```bash
   ls -la ~/.config/noctalia/config.toml
   # Phải trỏ đúng về ~/Workspaces/dotfiles/modules/noctalia/files/config.toml (không bị broken)
   ```
2. **Kiểm tra Notification Daemon:**
   ```bash
   notify-send "Test" "Noctalia Notification đang hoạt động"
   # Popup thông báo phải xuất hiện mượt mà trên desktop
   ```
3. **Kiểm tra Screenshot Annotation:**
   Bấm `Mod + Shift + S` (hoặc chạy `noctalia msg screenshot-annotate`), màn hình đóng băng và hiện thanh công cụ vẽ chú thích.
