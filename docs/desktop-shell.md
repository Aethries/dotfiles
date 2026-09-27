# 🎨 Desktop Shell & Đăng Nhập (Noctalia & Greetd)

Tài liệu này mô tả giao diện desktop shell **Noctalia** và màn hình đăng nhập hệ thống **greetd** kết hợp với **noctalia-greeter**.

---

## 1. Cấu Trúc Module

- **Desktop Shell:** `modules/noctalia/` (cấu hình đặt tại `~/.config/noctalia/`)
- **Greeter Đăng Nhập:** `modules/greeter/` (cấu hình triển khai vào `/etc/greetd/config.toml`)

---

## 2. Desktop Shell Noctalia

Noctalia là desktop shell hiện đại dành cho Wayland, cung cấp thanh panel trạng thái, widget điều khiển và launcher tìm kiếm ứng dụng.

### Các thành phần chính:
- **Thanh Panel (Bar):** Hiển thị danh sách workspace, thời gian, trạng thái pin, mạng Wi-Fi và âm lượng.
- **Launcher:** Trình mở ứng dụng thông minh. Có thể bật/tắt bằng phím tắt `Super + Space` thông qua IPC:
  ```bash
  noctalia msg panel-toggle launcher
  ```
- **Control Center:** Bảng điều khiển trung tâm quản lý âm thanh, Bluetooth, Wi-Fi và độ sáng màn hình.
- **Chủ đề màu sắc (Theming):** Tích hợp Matugen để tự động tạo bảng màu Material You hài hòa theo hình nền và đồng bộ vào Starship prompt, Kitty.

---

## 3. Màn Hình Đăng Nhập (greetd + noctalia-greeter)

Hệ thống sử dụng `greetd` làm login daemon và `noctalia-greeter` làm giao diện đăng nhập đồ họa Wayland.

### Luồng khởi động và đăng nhập:
1. Khi hệ thống boot vào TTY 1 (`vt = 1`), `greetd.service` chạy lệnh:
   ```toml
   [terminal]
   vt = 1

   [default_session]
   command = "/usr/bin/noctalia-greeter-session -- --session Umbriel"
   user = "greeter"
   ```
2. `noctalia-greeter` khởi chạy màn hình chọn người dùng và nhập mật khẩu.
3. Tham số `--session Umbriel` ghim sẵn phiên desktop mặc định là **Umbriel**.
4. Khi người dùng nhập đúng mật khẩu, `greetd` nạp file session `/usr/share/wayland-sessions/umbriel.desktop` và thực thi lệnh:
   ```bash
   start-umbriel
   ```
5. Đưa người dùng vào thẳng môi trường làm việc Umbriel Compositor với quyền người dùng thông thường.

---

## 4. Quản Lý & Vận Hành

```bash
# Kiểm tra trạng thái dịch vụ greetd
systemctl status greetd

# Kiểm tra IPC của Noctalia từ terminal
noctalia msg status

# Nạp lại cấu hình hoặc đổi theme mode
noctalia msg theme-mode-toggle
```
