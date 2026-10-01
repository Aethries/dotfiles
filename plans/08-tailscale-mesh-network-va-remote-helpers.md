# Kế hoạch 08: Mạng Lưới Bảo Mật Tailscale Mesh, Tailscale SSH và Remote Helpers

## 1. Tên chức năng
**Thiết Lập Mạng Riêng Ảo Tailscale Mesh, Tailscale SSH Không Cần Quản Lý Khóa Thủ Công và Bộ Công Cụ Thao Tác File Từ Xa.**

---

## 2. Mô tả chức năng

### 2.1. Vấn đề hiện tại
* Công việc phát triển đòi hỏi kết nối liên tục giữa nhiều thiết bị: Máy trạm tại nhà (workstation), Laptop di động, VPS đám mây và thiết bị di động.
* Mở port SSH (port 22) trực tiếp ra Internet qua router tiềm ẩn nguy cơ bảo mật nghiêm trọng (bị bot quét port, brute force password).
* IP mạng gia đình thường xuyên thay đổi (Dynamic IP), khiến các kết nối SSH và remote desktop bị gián đoạn.
* Việc mount thư mục từ xa để đọc ghi file hoặc đồng bộ dữ liệu giữa các máy chưa có workflow tự động, phải gõ các lệnh rsync/sshfs thủ công dài dòng.

### 2.2. Mục tiêu kỹ thuật
1. **Mạng lưới Tailscale Mesh (Tailnet):**
   * Kết nối tất cả các thiết bị vào một mạng VPN ngang hàng (P2P WireGuard) hoàn toàn bảo mật.
   * Cấp địa chỉ IP cố định (100.x.y.z) và tên miền MagicDNS cho từng máy (ví dụ: `workstation`, `laptop`, `vps-sg`).
2. **Tailscale SSH:**
   * Tự động xác thực phiên SSH thông qua tài khoản Tailscale và chính sách ACL mà không cần phải thủ công tạo và copy `authorized_keys` sang từng máy.
3. **Bộ Remote Helpers & SSH Client Tối Ưu:**
   * Cấu hình SSH Client: `ControlMaster` và `ControlPersist` giúp tái sử dụng socket kết nối, giảm độ trễ khi chạy nhiều lệnh SSH liên tiếp về 0.
   * Bộ lệnh tiện ích trong shell: `ssh-mount`, `ssh-umount`, `ssh-sync`, `ssh-forward`.
   * Tích hợp `mosh` (Mobile Shell) giúp duy trì phiên terminal liên tục kể cả khi đổi mạng Wi-Fi hoặc gập nắp laptop.

---

## 3. Chi tiết triển khai

### 3.1. Các file cần tạo và sửa đổi

* **[MODIFY]** [packages/pacman.txt](file:///home/loc/Workspaces/dotfiles/packages/pacman.txt): Thêm `tailscale`, `sshfs`, `mosh`.
* **[NEW]** `modules/tailscale/setup.sh`: Script kích hoạt `tailscaled.service` và thiết lập cấu hình.
* **[NEW]** `modules/tailscale/files/ssh_config`: Snippet cấu hình SSH tối ưu (`ControlMaster`, keepalive).
* **[MODIFY]** [modules/shell/files/.zshrc](file:///home/loc/Workspaces/dotfiles/modules/shell/files/.zshrc): Bổ sung các helper function thao tác remote.
* **[MODIFY]** [install.sh](file:///home/loc/Workspaces/dotfiles/install.sh): Thêm lệnh thực thi `modules/tailscale/setup.sh`.

### 3.2. Cấu hình chi tiết Helper Functions trong `.zshrc`

```bash
# ------------------------------------------------------------------------------
# Remote Development & File System Helpers
# ------------------------------------------------------------------------------

# Mount thư mục từ xa vào ~/mnt/remote/<host>
function ssh-mount() {
    local host="${1:-}"
    local remote_path="${2:-/}"
    if [[ -z "$host" ]]; then
        echo "Cách dùng: ssh-mount <host> [remote_path]"
        return 1
    fi
    local mount_point="$HOME/mnt/remote/$host"
    mkdir -p "$mount_point"
    sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 "$host:$remote_path" "$mount_point"
    echo "✓ Đã mount $host:$remote_path tại $mount_point"
}

# Ngắt mount an toàn
function ssh-umount() {
    local host="${1:-}"
    if [[ -z "$host" ]]; then
        echo "Cách dùng: ssh-umount <host>"
        return 1
    fi
    local mount_point="$HOME/mnt/remote/$host"
    fusermount3 -u "$mount_point" && rmdir "$mount_point" 2>/dev/null || true
    echo "✓ Đã ngắt mount $host"
}

# Đồng bộ nhanh thư mục local lên remote qua rsync
function ssh-sync() {
    local host="${1:-}"
    local local_dir="${2:-}"
    local remote_dir="${3:-}"
    if [[ -z "$host" || -z "$local_dir" || -z "$remote_dir" ]]; then
        echo "Cách dùng: ssh-sync <host> <local_dir> <remote_dir>"
        return 1
    fi
    rsync -avz --progress --exclude '.git' --exclude 'node_modules' "$local_dir/" "$host:$remote_dir/"
}
```

---

## 4. Hướng dẫn sử dụng

### 4.1. Gia nhập Tailnet và Kích hoạt Tailscale SSH
```bash
# 1. Kích hoạt kết nối và cấp quyền Tailscale SSH
sudo tailscale up --ssh

# 2. Kiểm tra danh sách các thiết bị trong mạng Tailnet
tailscale status
```

### 4.2. Thao tác Remote Workstation hằng ngày

```bash
# SSH tức thì vào máy trạm qua MagicDNS (không cần nhớ IP, không cần mật khẩu)
ssh workstation

# Kết nối mượt mà không bao giờ bị ngắt kết nối (kể cả khi mất mạng tạm thời)
mosh workstation

# Mount toàn bộ source code của máy trạm về laptop để duyệt file trên Yazi local
ssh-mount workstation /home/loc/Workspaces
# Mở Yazi duyệt file như trên ổ cứng cục bộ:
yazi ~/mnt/remote/workstation

# Ngắt mount sau khi xong việc
ssh-umount workstation
```

---

## 5. Tiêu chuẩn kiểm thử & Nghiệm thu (Verification)

1. **Kiểm tra Tailscale daemon:**
   ```bash
   systemctl is-active tailscaled
   # Phải trả về: active
   ```
2. **Kiểm tra ping nội bộ qua Tailnet:**
   ```bash
   tailscale ping workstation
   # Phải phản hồi gói tin qua kết nối trực tiếp (direct wireguard peer)
   ```
3. **Kiểm tra tính năng SSHFS Mount:**
   * Chạy `ssh-mount workstation /tmp`.
   * Thử `touch ~/mnt/remote/workstation/test.txt`.
   * File phải xuất hiện tức thì trong `/tmp` của máy trạm.
