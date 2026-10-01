# Kế hoạch 02: Chuẩn hóa Session Environment và WebRTC Screen Sharing Wayland

## 1. Tên chức năng
**Chuẩn hóa Biến Môi Trường Cấp Session (`environment.d`) và Kích Hoạt WebRTC PipeWire Screen Sharing cho Chrome & Electron.**

---

## 2. Mô tả chức năng

### 2.1. Vấn đề hiện tại
* Nhiều biến môi trường tối quan trọng cho Wayland hiện chỉ được khai báo trong `.zshrc` (như `ELECTRON_OZONE_PLATFORM_HINT="auto"`, `XMODIFIERS="@im=fcitx"`, `QT_IM_MODULE=fcitx`).
* Khi người dùng mở ứng dụng GUI (Chrome, Slack, Lark, Beekeeper Studio, Postman) từ **Noctalia Launcher** hoặc **phím tắt Umbriel**, các ứng dụng này được khởi tạo trực tiếp từ session compositor / systemd user session mà **không thông qua shell Zsh**. Hệ quả là ứng dụng có thể chạy qua lớp XWayland trung gian, mờ nét hoặc không gõ được tiếng Việt ổn định.
* Screen sharing trên Google Meet (Chrome), Slack và Lark thường xuyên bị lỗi màn hình đen hoặc không hiện popup chọn cửa sổ chia sẻ do thiếu cờ kích hoạt WebRTC PipeWire capturer.
* File `modules/vault/files/chrome-flags.conf` hiện chỉ chứa duy nhất `--password-store=gnome-libsecret`.

### 2.2. Mục tiêu kỹ thuật
1. Tạo module `modules/env/` để quản lý biến môi trường cấp session thông qua chuẩn `~/.config/environment.d/00-wayland.conf`. Chuẩn này được PAM, systemd user session và các Wayland compositor nạp tự động khi đăng nhập.
2. Cấu hình cờ Ozone Wayland và WebRTC PipeWire capturer cho trình duyệt Google Chrome (`~/.config/chrome-flags.conf`).
3. Cấu hình cờ tương thích cho các ứng dụng nền tảng Electron như Slack, Lark (`~/.config/electron-flags.conf`).
4. Khai thác đúng portal `xdg-desktop-portal-umbriel` (đã có sẵn) mà không cần cài đặt thêm các portal bên ngoài.

---

## 3. Chi tiết triển khai

### 3.1. Các file cần tạo và sửa đổi

* **[NEW]** `modules/env/files/00-wayland.conf`: Định nghĩa biến môi trường session.
* **[NEW]** `modules/env/setup.sh`: Tạo symlink vào `~/.config/environment.d/00-wayland.conf`.
* **[MODIFY]** `modules/vault/files/chrome-flags.conf`: Bổ sung cờ Ozone và PipeWire capturer.
* **[NEW]** `modules/env/files/electron-flags.conf`: Cờ cấu hình cho ứng dụng Electron.
* **[MODIFY]** [install.sh](file:///home/loc/Workspaces/dotfiles/install.sh): Thêm bước chạy `modules/env/setup.sh`.

### 3.2. Nội dung cấu hình chi tiết

#### File `modules/env/files/00-wayland.conf`
```ini
# Wayland Core & Ozone Configuration
ELECTRON_OZONE_PLATFORM_HINT=auto
MOZ_ENABLE_WAYLAND=1
QT_QPA_PLATFORM=wayland;xcb
GDK_BACKEND=wayland,x11,*
CLUTTER_BACKEND=wayland

# Fcitx5 Vietnamese Input Method for GUI
XMODIFIERS=@im=fcitx
QT_IM_MODULE=fcitx

# SDL & Video Acceleration
SDL_VIDEODRIVER=wayland
_JAVA_AWT_WM_NONREPARENTING=1
```

#### File `modules/vault/files/chrome-flags.conf`
```text
--password-store=gnome-libsecret
--ozone-platform-hint=auto
--enable-features=WaylandWindowDecorations,WebRTCPipeWireCapturer
```

#### File `modules/env/files/electron-flags.conf` (symlink tới `~/.config/electron-flags.conf`)
```text
--ozone-platform-hint=auto
--enable-features=WaylandWindowDecorations,WebRTCPipeWireCapturer
```

---

## 4. Hướng dẫn sử dụng

### 4.1. Quy trình kiểm tra chia sẻ màn hình trên Google Meet / Slack / Lark
1. Mở Google Meet trong Google Chrome hoặc mở cuộc gọi trong ứng dụng Slack/Lark.
2. Bấm nút **Share Screen (Chia sẻ màn hình)**.
3. Portal `xdg-desktop-portal-umbriel` sẽ hiển thị hộp thoại hệ thống cho phép chọn:
   * Toàn bộ màn hình (Monitor).
   * Cửa sổ ứng dụng cụ thể (Window).
4. Chọn nguồn phát và nhấn **Share**. Hình ảnh hiển thị mượt mà với 60 FPS qua PipeWire, không bị giật lag hay màn hình đen.

### 4.2. Gõ tiếng Việt trong ứng dụng GUI
* Bật Chrome, Slack hoặc Lark từ Noctalia Launcher (`Mod + Space`).
* Thử gõ văn bản tiếng Việt có dấu (`Fcitx5 Bamboo`): phím bấm mượt mà, dấu hiển thị chuẩn xác, không bị nuốt ký tự hoặc nhảy focus.

---

## 5. Tiêu chuẩn kiểm thử & Nghiệm thu (Verification)

1. **Kiểm tra biến môi trường session:**
   ```bash
   systemctl --user show-environment | grep -E "OZONE|XMODIFIERS|WAYLAND"
   # Các biến phải hiển thị đầy đủ trong session của systemd
   ```
2. **Kiểm tra PipeWire ScreenCast Portal:**
   ```bash
   /usr/lib/xdg-desktop-portal -r &
   # Đảm bảo xdg-desktop-portal-umbriel đang phản hồi trên DBus org.freedesktop.impl.portal.desktop.umbriel
   ```
3. **Kiểm tra Chrome chạy native Wayland:**
   * Mở Chrome, truy cập `chrome://gpu`.
   * Tìm mục **Ozone platform**: giá trị phải là `wayland`.
