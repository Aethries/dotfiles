# 🗂️ Quản Lý Phiên Làm Việc Terminal (Zellij Multiplexer)

Tài liệu này mô tả cấu hình cho **Zellij**, terminal multiplexer hiện đại viết bằng Rust thay thế cho tmux, hỗ trợ hệ thống layout linh hoạt và các plugin biên dịch ra WebAssembly (WASM).

---

## 1. Cấu Trúc Module

- **Mã nguồn module:** `modules/zellij/`
- **Script cài đặt:** `modules/zellij/setup.sh`
- **File cấu hình:** Được symlink vào `~/.config/zellij/`:
  - `config.kdl`: File cấu hình chính dạng KDL syntax.
  - `layouts/`: Các bố cục màn hình mẫu (default, code, compact...).
  - `plugins/`: Thư mục chứa các plugin WASM đã ghim sẵn.
  - `themes/`: Bảng màu giao diện.

---

## 2. Các Plugin WASM Ghim Sẵn (Pinned Plugins)

Hệ thống tích hợp sẵn các plugin WASM hiệu năng cao:

1. **`zjstatus.wasm`**:
   - Thanh trạng thái thanh lịch ở cạnh dưới hoặc cạnh trên.
   - Hiển thị tab đang chọn, chế độ bàn phím hiện tại (Normal, Locked, Pane, Tab, Resize...), tên session và thông tin Git.
2. **`vim-zellij-navigator.wasm`**:
   - Cho phép điều hướng mượt mà không phân biệt ranh giới giữa các pane của Zellij và các split của Neovim thông qua tổ hợp phím `Ctrl + h/j/k/l`.
3. **`zellij-forgot.wasm`**:
   - Menu tra cứu phím tắt nhanh dạng popup nổi trên màn hình.

---

## 3. Thao Tác Cơ Bản Với Zellij

```bash
# Bắt đầu session mới hoặc gắn vào session mặc định
zellij

# Liệt kê các session đang chạy trong nền
zellij list-sessions

# Gắn vào một session theo tên
zellij attach <ten-session>

# Xóa các session đã chết (resurrect/dead)
zellij delete-all-sessions --force
```

### Các phím tắt thông dụng (Chế độ mặc định):
- `Ctrl + p` + `n`: Tạo pane mới.
- `Ctrl + p` + `x`: Đóng pane hiện tại.
- `Ctrl + t` + `n`: Tạo tab mới.
- `Ctrl + o` + `d`: Đưa session về chạy ngầm (detach).
