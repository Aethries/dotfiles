# Kế hoạch 09: Sunshine Remote Desktop Chuyên Sâu Cho Lập Trình (Headless HDMI Dummy Plug & Moonlight)

## 1. Tên chức năng
**Thiết Lập Giải Pháp Remote Desktop Hiệu Năng Cao Cho Máy Trạm Bằng Sunshine (Headless Display Vật Lý) và Moonlight Qua Tailscale.**

---

## 2. Mô tả chức năng

### 2.1. Vấn đề hiện tại
* Lập trình viên thường xuyên cần làm việc từ xa (từ quán cà phê, khi đi công tác) bằng laptop mỏng nhẹ nhưng vẫn muốn tận dụng toàn bộ sức mạnh CPU/GPU và RAM của máy trạm cố định ở nhà.
* **Vấn đề Headless Display trên Wayland:** Khi tắt màn hình vật lý của máy trạm hoặc không cắm cáp HDMI/DisplayPort, card đồ họa rời (GPU) sẽ ngắt kích hoạt cổng xuất hình. Việc stream màn hình từ xa sẽ bị đen hoặc tụt độ phân giải về 640x480.
* Các giải pháp tạo màn hình ảo bằng phần mềm trên Wayland (`vkms`, `evdi`) rất kém ổn định và thường xuyên phát sinh lỗi với driver Nvidia/AMD sau mỗi lần nâng cấp kernel.
* Các phần mềm remote thương mại (TeamViewer, AnyDesk) có độ trễ cao (30-100ms), giới hạn 30 FPS, làm mờ chữ và tiêu tốn nhiều tài nguyên CPU.
* Mở port streaming ra Internet tiềm ẩn rủi ro tấn công mạng.

### 2.2. Mục tiêu kỹ thuật
1. **Host (Máy trạm):**
   * Cài đặt **Sunshine** chạy dưới dạng `systemd --user` service.
   * Tận dụng tối đa bộ mã hóa phần cứng của GPU: **NVENC** (card Nvidia) hoặc **VAAPI** (card AMD/Intel) để đạt tốc độ stream 60 - 120 FPS với độ trễ cực thấp (< 5ms).
   * **Giải pháp Headless Display thực dụng:** Sử dụng **HDMI Dummy Plug 4K** (phần cứng vật lý cắm vào GPU máy trạm) để duy trì tín hiệu xuất hình 2K/4K 60-120Hz ổn định 24/7 mà không lo lỗi phần mềm.
   * **Bảo mật tuyệt đối:** Cấu hình Sunshine chỉ lắng nghe trên interface nội bộ của mạng **Tailscale** (không mở bất kỳ port nào ra ngoài Internet).
   * Tích hợp âm thanh PipeWire, microphone và đồng bộ clipboard hai chiều giữa client và host.
   * Tự động khóa màn hình máy trạm khi phiên remote kết thúc.
2. **Client (Laptop / Tablet):**
   * Cài đặt **Moonlight** (`moonlight-qt`) để kết nối mượt mà về máy trạm.

---

## 3. Chi tiết triển khai

### 3.1. Các file cần tạo và sửa đổi

* **[MODIFY]** [packages/aur.txt](file:///home/loc/Workspaces/dotfiles/packages/aur.txt): Thêm `sunshine`.
* **[MODIFY]** [packages/pacman.txt](file:///home/loc/Workspaces/dotfiles/packages/pacman.txt): Thêm `moonlight-qt` (trên client).
* **[NEW]** `modules/sunshine/files/sunshine.conf`: Cấu hình độ phân giải, bitrate, encoder và bảo mật IP Tailscale.
* **[NEW]** `modules/sunshine/setup.sh`: Script cấp quyền KMS/udev cho user và kích hoạt systemd user service.
* **[MODIFY]** [install.sh](file:///home/loc/Workspaces/dotfiles/install.sh): Thêm lệnh thực thi `modules/sunshine/setup.sh`.

### 3.2. Cấu hình chi tiết `modules/sunshine/files/sunshine.conf`

```text
# ~/.config/sunshine/sunshine.conf
origin_web_ui_allowed = lan
address = 100.64.0.0/10  # Chỉ cho phép dải IP nội bộ của Tailscale kết nối
port = 47989

# GPU Encoder & Display Resolution
encoder = nvenc          # nvenc (Nvidia) hoặc vaapi (AMD/Intel)
fps = [60, 120]
resolutions = [
    1920x1080,
    2560x1440,
    3840x2160
]

# Audio & Input
audio_sink = auto
channels = 2
back_button_behavior = 0

# Security & Behavior
origin_pin_allowed = lan
exit_action = "noctalia msg session lock"
```

---

## 4. Hướng dẫn sử dụng

### 4.1. Chuẩn bị Phần cứng & Kích hoạt trên Máy trạm (Host)
1. Cắm đầu **HDMI Dummy Plug 4K** vào một cổng HDMI trống trên card đồ họa máy trạm.
2. Kích hoạt Sunshine service:
   ```bash
   systemctl --user enable --now sunshine.service
   ```
3. Mở trình duyệt truy cập bảng điều khiển quản trị: `https://localhost:47990` (hoặc truy cập qua IP Tailscale từ xa).
4. Đặt Username và Password quản trị theo hướng dẫn trên màn hình.

### 4.2. Ghép đôi & Kết nối từ Laptop (Client)
1. Mở ứng dụng **Moonlight** trên laptop hoặc iPad.
2. Bấm nút **Add Host** -> Nhập địa chỉ MagicDNS hoặc IP Tailscale của máy trạm (ví dụ: `workstation` hoặc `100.x.y.z`).
3. Moonlight sẽ hiển thị một mã PIN 4 chữ số.
4. Truy cập web UI của Sunshine trên máy trạm (`PIN tab`) -> Nhập mã PIN để hoàn tất ghép đôi.
5. Bấm vào icon Desktop trên Moonlight: Giao diện máy trạm hiển thị tức thì với độ phân giải sắc nét, màu sắc chuẩn xác và độ trễ thao tác gần như bằng 0.

---

## 5. Tiêu chuẩn kiểm thử & Nghiệm thu (Verification)

1. **Kiểm tra trạng thái Service:**
   ```bash
   systemctl --user status sunshine.service
   # Service phải ở trạng thái active (running)
   ```
2. **Kiểm tra cổng dịch vụ ràng buộc đúng IP Tailscale:**
   ```bash
   sudo ss -tulpn | grep sunshine
   # Cổng 47989 và 47990 chỉ lắng nghe trên interface tailscale0 hoặc localhost
   ```
3. **Kiểm tra kết nối thực tế:**
   * Tắt màn hình vật lý của máy trạm.
   * Kết nối thử từ laptop: Màn hình vẫn nhận diện độ phân giải 2K/4K mượt mà, âm thanh và bàn phím phản hồi tức thì.
