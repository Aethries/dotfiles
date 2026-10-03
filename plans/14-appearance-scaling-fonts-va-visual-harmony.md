# Kế hoạch 14: Đồng Bộ Giao Diện, Tỷ Lệ Hiển Thị (Scale) & Visual Harmony Toàn Hệ Thống

## 1. Tên chức năng
**Hệ Thống Quản Trị Giao Diện Hợp Nhất: Display Scale, Typography, Cursor & Đồng Bộ Màu Sắc (Noctalia, GTK, Qt, Wayland & Electron).**

---

## 2. Mô tả chức năng

### 2.1. Vấn đề hiện tại
* Màn hình máy tính hiện đại (FullHD 1080p, 2K 1440p, 4K) và hệ thống đa màn hình thường gặp tình trạng:
  * Tỷ lệ hiển thị (Scale) không đồng nhất: Một số ứng dụng Electron (Chrome, Slack, VS Code) bị mờ do chạy qua XWayland hoặc scale không đúng tỉ lệ.
  * Cỡ chữ (Font size) lệch nhau: Terminal quá nhỏ trong khi thanh menu hoặc IDE quá to.
  * Con trỏ chuột (Cursor) bị giật kích thước: Khi di chuột từ màn hình desktop vào ứng dụng GTK, Qt hoặc trình duyệt, kích thước con trỏ chuột thay đổi thất thường (lúc 24px, lúc 32px, lúc 16px).
  * Ứng dụng Qt (như Telegram) và GTK không nhận diện đúng chế độ Dark Mode của hệ thống.

### 2.2. Mục tiêu kỹ thuật
1. **Chuẩn hóa Tỷ lệ Hiển thị (Display & UI Scale)**:
   * Cấu hình scale chuẩn trong compositor Umbriel (`modules/umbriel/files/config.toml` - ví dụ `1.0` cho 1080p, `1.25` cho 2K).
   * Đồng bộ `ui_scale = 0.9` trong Noctalia Desktop Shell.
   * Kích hoạt cờ native Wayland cho toàn bộ ứng dụng Electron/Chromium để loại bỏ hoàn toàn hiện tượng mờ chữ.
   * Đồng bộ biến môi trường GTK (`GDK_SCALE`, `GDK_DPI_SCALE`) và Qt (`QT_SCALE_FACTOR`, `QT_AUTO_SCREEN_SCALE_FACTOR`).
2. **Chuẩn hóa Phông chữ Toàn Cục (Typography & Fontconfig)**:
   * Phông chữ lập trình và terminal: `JetBrains Mono Nerd Font` (bật font ligatures, tối ưu khoảng cách chữ).
   * Phông chữ giao diện (UI): `Inter` hoặc `JetBrains Mono Nerd Font`.
   * Cấu hình [modules/fonts/files/fonts.conf](file:///home/loc/Workspaces/dotfiles/modules/fonts/files/fonts.conf) tối ưu khử răng cưa (Antialiasing), khử màu viền chữ (Subpixel RGB rendering) và Hinting (`slight`).
3. **Đồng bộ Con trỏ Chuột (Cursor Harmony)**:
   * Thống nhất Cursor Theme: `Bibata-Modern-Classic` (hoặc `Adwaita`).
   * Thống nhất Cursor Size: `24` trên toàn bộ các tầng (Wayland, XWayland, GTK 3/4, Qt6, Electron).
4. **Hòa hợp Giao diện Ứng dụng (GTK & Qt Theming)**:
   * Đặt biến chuẩn XDG Desktop Portal: `color-scheme: prefer-dark`.
   * Cấu hình GTK 3 (`~/.config/gtk-3.0/settings.ini`) và GTK 4 (`~/.config/gtk-4.0/settings.ini`) tự động kích hoạt `gtk-application-prefer-dark-theme=1`.
   * Tích hợp `qt6ct` / `qt5ct` để các ứng dụng Qt (Telegram, Wireshark, VLC) nhận diện theme tối và font JetBrains Mono.

---

## 3. Chi tiết triển khai

### 3.1. Các file cấu hình cần tạo và chuẩn hóa

* **[NEW]** `modules/session/files/environment.d/10-appearance.conf`: Biến môi trường toàn cục cho Cursor, GTK, Qt và Scale.
* **[NEW]** `modules/session/files/gtk-3.0/settings.ini`: Thiết lập Dark mode, font và cursor cho GTK 3.
* **[NEW]** `modules/session/files/gtk-4.0/settings.ini`: Thiết lập cho GTK 4.
* **[MODIFY]** [modules/fonts/files/fonts.conf](file:///home/loc/Workspaces/dotfiles/modules/fonts/files/fonts.conf): Tối ưu quy tắc render font hệ thống.
* **[MODIFY]** [modules/umbriel/files/config.toml](file:///home/loc/Workspaces/dotfiles/modules/umbriel/files/config.toml): Cấu hình scale màn hình, cursor theme và size.
* **[MODIFY]** [modules/noctalia/files/settings.toml](file:///home/loc/Workspaces/dotfiles/modules/noctalia/files/settings.toml): Duy trì `ui_scale = 0.9` và font family đồng bộ.

### 3.2. Cấu hình chi tiết mẫu

#### 1. Biến môi trường toàn cục: `10-appearance.conf`
```ini
# Cursor Theme & Size
XCURSOR_THEME=Bibata-Modern-Classic
XCURSOR_SIZE=24

# GTK & Qt Dark Mode & Rendering
GTK_THEME=Adwaita:dark
QT_QPA_PLATFORM=wayland;xcb
QT_QPA_PLATFORMTHEME=qt6ct
QT_WAYLAND_DISABLE_WINDOWDECORATION=1
QT_AUTO_SCREEN_SCALE_FACTOR=1

# Electron & Chromium Native Wayland
ELECTRON_OZONE_PLATFORM_HINT=auto
```

#### 2. GTK Settings (`~/.config/gtk-3.0/settings.ini`)
```ini
[Settings]
gtk-theme-name = Adwaita-dark
gtk-icon-theme-name = Papirus-Dark
gtk-font-name = JetBrainsMono Nerd Font 10
gtk-cursor-theme-name = Bibata-Modern-Classic
gtk-cursor-theme-size = 24
gtk-application-prefer-dark-theme = 1
```

#### 3. Umbriel Compositor Display & Cursor (`modules/umbriel/files/config.toml`)
```toml
# Cursor
cursor_theme = "Bibata-Modern-Classic"
cursor_size = 24

# Outputs scale
[outputs.HDMI-A-1]
scale = 1.0
mode = "1920x1080@120Hz"

[outputs.HDMI-A-2]
scale = 1.0
mode = "1920x1080@120Hz"
```

---

## 4. Hướng dẫn sử dụng & Kiểm thử nghiệm thu (Verification)

1. **Kiểm tra Scale:**
   Mở Chrome, Kitty, VS Code và Telegram trên các màn hình; độ sắc nét phông chữ hiển thị 1:1, không bị răng cưa hoặc mờ do upscale.
2. **Kiểm tra Con trỏ Chuột (Cursor):**
   Di chuyển chuột giữa các vùng desktop, thanh bar Noctalia, cửa sổ Chrome, Telegram và Kitty; con trỏ giữ nguyên hình dáng `Bibata-Modern-Classic` với kích thước chuẩn 24px.
3. **Kiểm tra Dark Mode toàn hệ thống:**
   Kiểm tra lệnh:
   ```bash
   gsettings get org.gnome.desktop.interface color-scheme
   # Kết quả: 'prefer-dark'
   ```
   Mọi ứng dụng GTK và Qt tự động khởi động ở giao diện nền tối.
