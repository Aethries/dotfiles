# 💻 Trình Giả Lập Terminal (Kitty)

Tài liệu này mô tả cấu hình cho trình giả lập dòng lệnh **Kitty**, hỗ trợ tăng tốc phần cứng GPU (OpenGL).

---

## 1. Cấu Trúc Module

- **Mã nguồn module:** `modules/kitty/`
- **Script cài đặt:** `modules/kitty/setup.sh`
- **File cấu hình:** Được symlink vào `~/.config/kitty/`:
  - `kitty.conf`: File cấu hình chính (font chữ, layout, keybinds, cuộn trang).
  - `themes/`: Thư mục chứa các bảng màu tùy chọn.

---

## 2. Các Thiết Lập Chính

### A. Phông Chữ & Hiển Thị
- **Font gia đình:** `JetBrainsMono Nerd Font` (hỗ trợ đầy đủ ligatures và icons).
- **Kích thước:** `font_size 12.0`.
- **Render đồ họa:** Hỗ trợ giao thức Kitty Graphics Protocol cho phép hiển thị ảnh trực tiếp trong terminal (tương thích hoàn hảo với Yazi preview).
- **Độ trong suốt & Padding:** Viền đệm nhẹ nhàng, không gây mỏi mắt khi làm việc lâu.

### B. Quản Lý Tab & Cửa Sổ Phân Chia (Splits)
- Hỗ trợ tạo tab mới, chia màn hình dọc/ngang (splits) linh hoạt.
- Phím tắt mở terminal toàn hệ thống: `Super + T` (được đăng ký qua Umbriel keybinds).

---

## 3. Quản Lý & Vận Hành

```bash
# Nạp lại cấu hình Kitty trực tiếp trong cửa sổ đang mở
Ctrl + Shift + F5

# Kiểm tra khả năng hỗ trợ font và icon
kitty --debug-font-fallback
```
