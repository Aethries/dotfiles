# Kế hoạch 03: Quản lý Lịch sử Clipboard Wayland (`cliphist`)

## 1. Tên chức năng
**Tích Hợp Quản Lý Lịch Sử Clipboard Toàn Hệ Thống (`cliphist`) trên Wayland.**

---

## 2. Mô tả chức năng

### 2.1. Vấn đề hiện tại
* Hệ thống hiện tại chỉ có `wl-clipboard` (`wl-copy`, `wl-paste`). Khi copy một đoạn văn bản mới, nội dung cũ lập tức bị ghi đè và mất hoàn toàn.
* Thường xuyên phải chuyển qua lại giữa các cửa sổ để copy nhiều đoạn code, link, mã token hoặc hình ảnh.
* Chưa có cơ chế bảo vệ clipboard khỏi các nội dung nhạy cảm từ password manager.

### 2.2. Mục tiêu kỹ thuật
1. Cài đặt `cliphist` (công cụ quản lý lịch sử clipboard hiệu năng cao viết bằng Go cho Wayland).
2. Thiết lập background watcher tự động lưu cả **văn bản (text)** và **hình ảnh (binary/png)** qua `systemd --user` service.
3. Tích hợp giao diện tìm kiếm lịch sử clipboard vào:
   * **Noctalia Launcher / dmenu:** Mở popup chọn nhanh qua phím tắt `Mod + V`.
   * **Terminal (FZF widget):** Chọn nhanh và paste trực tiếp vào dòng lệnh.
4. Cung cấp lệnh dọn dẹp và xóa lịch sử khi cần bảo mật.

---

## 3. Chi tiết triển khai

### 3.1. Các file cần tạo và sửa đổi

* **[MODIFY]** [packages/pacman.txt](file:///home/loc/Workspaces/dotfiles/packages/pacman.txt): Thêm `cliphist`.
* **[NEW]** `modules/clipboard/files/cliphist.service`: Systemd user service tự động theo dõi clipboard.
* **[NEW]** `modules/clipboard/files/cliphist-picker.sh`: Script tích hợp gọi giao diện chọn clipboard qua Noctalia hoặc FZF.
* **[NEW]** `modules/clipboard/setup.sh`: Script cài đặt service và cấp quyền thực thi.
* **[MODIFY]** [modules/umbriel/files/keybinds.toml](file:///home/loc/Workspaces/dotfiles/modules/umbriel/files/keybinds.toml): Gắn phím tắt `Mod+V` để mở `cliphist-picker.sh`.
* **[MODIFY]** [modules/shell/files/.zshrc](file:///home/loc/Workspaces/dotfiles/modules/shell/files/.zshrc): Thêm alias hoặc widget `clip` / `fzf-clip`.

### 3.2. Cấu hình chi tiết

#### Systemd User Service: `modules/clipboard/files/cliphist.service`
```ini
[Unit]
Description=Cliphist Clipboard History Watcher
PartOf=graphical-session.target
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/wl-paste --watch /usr/bin/cliphist store
Restart=on-failure
RestartSec=2s

[Install]
WantedBy=default.target
```

#### Script Picker: `modules/clipboard/files/cliphist-picker.sh`
```bash
#!/usr/bin/env bash
set -euo pipefail

# Ưu tiên Noctalia dmenu nếu đang chạy trong GUI, fallback về fzf nếu chạy trong terminal
if [[ -t 0 ]]; then
    selected=$(cliphist list | fzf --prompt="📋 Clipboard > ")
else
    selected=$(cliphist list | noctalia dmenu --prompt "📋 Clipboard")
fi

if [[ -n "${selected:-}" ]]; then
    echo "$selected" | cliphist decode | wl-copy
    # Tự động gửi phím Shift+Insert hoặc Ctrl+V nếu cần paste tức thì
fi
```

---

## 4. Hướng dẫn sử dụng

### 4.1. Thao tác giao diện hằng ngày
1. **Mở lịch sử Clipboard:** Bấm phím tắt **`Mod + V`** ở bất kỳ đâu trên màn hình.
2. Hộp thoại tìm kiếm xuất hiện hiển thị danh sách các mục đã copy gần nhất (kèm timestamp rút gọn).
3. Gõ từ khóa để lọc nội dung cần tìm.
4. Bấm `Enter`: Nội dung tương ứng sẽ được nạp lại vào clipboard chính của hệ thống để sẵn sàng dán (`Ctrl + V`).

### 4.2. Thao tác trong dòng lệnh Terminal
```bash
# Xem và paste nội dung lịch sử trực tiếp trong terminal qua FZF
clip

# Xóa một mục cụ thể ra khỏi lịch sử
cliphist list | fzf | cliphist delete

# Xóa sạch toàn bộ lịch sử clipboard (sau khi làm việc với thông tin nhạy cảm)
cliphist wipe
```

---

## 5. Tiêu chuẩn kiểm thử & Nghiệm thu (Verification)

1. **Kiểm tra trạng thái daemon:**
   ```bash
   systemctl --user status cliphist.service
   # Trạng thái phải là active (running)
   ```
2. **Kiểm tra tính năng lưu trữ:**
   * Copy 3 đoạn text khác nhau ở 3 ứng dụng khác nhau.
   * Chạy `cliphist list`. Cả 3 đoạn text phải xuất hiện theo thứ tự mới nhất ở trên cùng.
3. **Kiểm tra phím tắt:**
   * Bấm `Mod + V`: Giao diện chọn clipboard phải xuất hiện tức thì mà không có độ trễ.
