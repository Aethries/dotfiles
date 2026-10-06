# Sunshine trên Arch / Umbriel

## Thiết lập máy mới qua SSH

Sau khi cài desktop bằng `./install.sh`, chạy từ thư mục dotfiles,
bằng tài khoản dùng desktop, không chạy cả script bằng sudo:

```bash
bash remote.sh
```

Script cần mật khẩu sudo tại terminal. Nó thiết lập Tailscale, autologin
greetd vào Umbriel, quyền thiết bị và Sunshine. Nếu Umbriel chưa chạy,
script xóa `/run/greetd.run` rồi restart greetd để chạy lại initial_session.
Phiên Umbriel đang hoạt động được giữ lại; Sunshine được restart để áp dụng
cấu hình, nên kết nối Moonlight hiện tại sẽ ngắt.

Cần có màn hình/output đang hoạt động và driver encoder phù hợp với GPU.
SSH không tự tạo màn hình. Script này chưa thiết lập màn hình ảo cho máy
không cắm monitor. Quyền nhóm mới không thay đổi các tiến trình đã chạy;
nếu còn lỗi quyền sau khi thêm nhóm, reboot để tạo lại cả user manager.

Ghép đôi Moonlight với IP từ `tailscale ip -4`, nhập PIN ở Web UI Sunshine
`https://<IP-Tailscale>:47990`, rồi mở Desktop để kiểm tra hình và âm thanh.

## Phục hồi 503 khi desktop đã thoát

Kiểm tra từ SSH:

```bash
systemctl --user status umbriel.service sunshine.service --no-pager
journalctl --user -u app-dev.lizardbyte.app.Sunshine.service -n 80 --no-pager
```

Nếu Umbriel không hoạt động và greetd đã có initial_session autologin:

```bash
sudo rm -f /run/greetd.run
sudo systemctl restart greetd.service
```

Đợi `systemctl --user is-active umbriel.service` trả về `active`, rồi:

```bash
systemctl --user reset-failed sunshine.service
systemctl --user restart sunshine.service
```

Nếu Umbriel chưa lên, đọc `journalctl --user -u umbriel.service` và
`sudo journalctl -u greetd.service`; không tiếp tục restart Sunshine.
Không lấy tên socket Wayland bằng `ls`: socket cũ có thể tồn tại khi
compositor đã chết. `start-umbriel` chạy qua greetd cung cấp phiên logind
và nạp môi trường Wayland cho systemd user.

`active (running)` chỉ xác nhận tiến trình Sunshine còn chạy. Log phải
thấy output và `Found H.264 encoder`/`Found HEVC encoder`; Moonlight phải
mở được Desktop để xác nhận stream.

## Cấu hình được quản lý

- `capture = wlr`: capture trực tiếp qua wlr screencopy của Umbriel.
- `system_tray = disabled`: không cần khay Qt; không đặt Qt toàn cục thành offscreen.
- Không cố định encoder, IP Tailscale, độ phân giải hoặc FPS của máy cũ.
- Không đặt `audio_sink = auto`: bỏ trống để dùng thiết bị âm thanh mặc định.
- Setup không cấp CAP_SYS_ADMIN cho chế độ này; gỡ capabilities KMS do
  script cũ cấp nếu còn tồn tại và có sudo.

Tham khảo: [cấu hình Sunshine](https://docs.lizardbyte.dev/projects/sunshine/latest/md_docs_2configuration.html).

### Phạm vi và lỗi

`modules/sunshine/setup.sh` nhận tài khoản/môi trường user hiện tại, liên kết
cấu hình, thiết lập quyền thiết bị và enable service. Nó chỉ restart Sunshine
khi managed Umbriel và graphical-session.target đang active cùng socket Wayland.
Lỗi systemd hoặc thao tác sudo đã thực hiện trả về nonzero; thiếu sudo được
báo kèm lệnh thủ công. `remote.sh` thiết lập các thành phần còn lại và đợi
Umbriel trả lời IPC tối đa 30 giây; nó không khởi chạy compositor trực tiếp từ SSH.

Autologin do remote.sh bật phù hợp với workstation truy cập từ xa. Để quay
lại cấu hình greetd trước đó, phục hồi `/etc/greetd/config.toml.pre-autologin.bak`
và xóa `.autologin` trong repo; restart greetd sẽ đóng phiên đồ họa hiện tại.
