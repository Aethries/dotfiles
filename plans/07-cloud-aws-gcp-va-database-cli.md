# Kế hoạch 07: Bộ Công Cụ Dòng Lệnh Cloud (AWS, GCP) và Universal Database CLI

## 1. Tên chức năng
**Chuẩn Hóa Bộ Công Cụ Dòng Lệnh Hạ Tầng Đám Mây (AWS SSO, GCP) và Trình Quản Trị Cơ Sở Dữ Liệu Tốc Độ Cao Trên Terminal.**

---

## 2. Mô tả chức năng

### 2.1. Vấn đề hiện tại
* Công việc hằng ngày thường xuyên tương tác với AWS, GCP và các hệ quản trị CSDL, nhưng dotfiles hiện tại hoàn toàn thiếu vắng các CLI chuyên dụng.
* **AWS SSO bất tiện:** Việc đăng nhập và chuyển đổi qua lại giữa hàng chục tài khoản/vai trò (roles) AWS qua giao diện web tốn nhiều thời gian và gây xung đột cookie trình duyệt.
* **GCP:** Chưa có `google-cloud-cli` và plugin xác thực Kubernetes (`gke-gcloud-auth-plugin`), gây khó khăn khi debug code local kết nối tới các dịch vụ Cloud Spanner, BigQuery, Pub/Sub.
* **Database:** Hiện chỉ có Beekeeper Studio (ứng dụng GUI). Khi cần chạy một câu query nhanh, kiểm tra dữ liệu hoặc chạy script bảo trì từ terminal, việc mở app GUI gây lãng phí tài nguyên và độ trễ thao tác.

### 2.2. Mục tiêu kỹ thuật
1. **AWS Workflow:**
   * Cài đặt `aws-cli-v2`.
   * Cài đặt `granted` (cung cấp lệnh `assume`): Cho phép chuyển đổi vai trò AWS SSO ngay trên terminal trong 1 giây và mở tab trình duyệt với session container riêng biệt cho từng role (không bao giờ bị đá phiên đăng nhập).
   * Cài đặt `aws-session-manager-plugin`: Kết nối SSH trực tiếp vào các máy ảo EC2 thông qua AWS Systems Manager (SSM) mà không cần mở port 22 hoặc dựng Bastion host.
2. **GCP & IaC Workflow:**
   * Cài đặt `google-cloud-cli` và `gke-gcloud-auth-plugin`.
   * Cấu hình Application Default Credentials (ADC) phục vụ chạy code local gọi Google Cloud APIs.
   * Quản lý cấu hình hạ tầng bằng `opentofu` và `terragrunt`.
3. **Database CLI siêu tốc:**
   * `usql`: Universal SQL CLI hỗ trợ PostgreSQL, MySQL, SQLite, Oracle, ClickHouse, SQL Server với cú pháp syntax highlighting và auto-completion.
   * `pgcli`: CLI chuyên biệt cho PostgreSQL với gợi ý thông minh về tên bảng, schema, cột và các hàm SQL.
   * `iredis`: CLI cho Redis với auto-completion lệnh và key.

---

## 3. Chi tiết triển khai

### 3.1. Các file cần tạo và sửa đổi

* **[MODIFY]** [packages/pacman.txt](file:///home/loc/Workspaces/dotfiles/packages/pacman.txt): Thêm `aws-cli-v2`, `opentofu`, `pgcli`, `iredis`.
* **[MODIFY]** [packages/aur.txt](file:///home/loc/Workspaces/dotfiles/packages/aur.txt): Thêm `granted-bin`, `google-cloud-cli`, `gke-gcloud-auth-plugin`, `usql-bin`.
* **[NEW]** `modules/cloud/files/granted.toml`: Cấu hình trình duyệt mặc định cho Granted (Chrome container).
* **[NEW]** `modules/cloud/setup.sh`: Script thiết lập completion cho shell và cấu hình ban đầu.
* **[MODIFY]** [modules/shell/files/.zshrc](file:///home/loc/Workspaces/dotfiles/modules/shell/files/.zshrc):
  * Thêm alias `assume="source /usr/bin/assume"`.
  * Thêm helper port-forwarding cho private database instances.
* **[MODIFY]** [install.sh](file:///home/loc/Workspaces/dotfiles/install.sh): Thêm bước chạy `modules/cloud/setup.sh`.

---

## 4. Hướng dẫn sử dụng

### 4.1. Thao tác với AWS SSO qua `granted`

```bash
# 1. Chuyển đổi vai trò AWS trên terminal (hiển thị menu chọn role thông minh)
assume

# 2. Chuyển đổi thẳng tới một role cụ thể
assume prod-admin

# 3. Mở AWS Console trên trình duyệt với container session tách biệt hoàn toàn
assume -c prod-admin

# 4. SSH vào EC2 private thông qua AWS SSM (không cần public IP hay mở port 22)
aws ssm start-session --target i-0123456789abcdef0
```

### 4.2. Thao tác với Google Cloud & GKE

```bash
# Đăng nhập tài khoản và thiết lập project mặc định
gcloud auth login
gcloud config set project my-gcp-project

# Cấp Application Default Credentials (ADC) cho môi trường dev local
gcloud auth application-default login

# Lấy credentials cụm GKE để sử dụng với kubectl
gcloud container clusters get-credentials my-cluster --region asia-southeast1
```

### 4.3. Truy vấn Database từ Terminal

```bash
# Truy vấn PostgreSQL với pgcli (tự động gợi ý cú pháp và schema)
pgcli postgres://postgres:password@localhost:5432/my_database

# Thao tác đa hệ CSDL bằng usql (Postgres, MySQL, SQLite, ClickHouse...)
usql postgres://user:pass@localhost/db
usql sqlite://mydb.sqlite3

# Thao tác Redis với iredis (auto-completion các lệnh SET, GET, HGETALL...)
iredis -h 127.0.0.1 -p 6379
```

---

## 5. Tiêu chuẩn kiểm thử & Nghiệm thu (Verification)

1. **Kiểm tra Granted CLI:**
   ```bash
   assume --version
   # Lệnh assume phải hoạt động và trả về phiên bản của Granted
   ```
2. **Kiểm tra Google Cloud CLI & Plugin GKE:**
   ```bash
   gcloud --version
   gke-gcloud-auth-plugin --version
   # Cả hai công cụ phải được cài đặt thành công
   ```
3. **Kiểm tra Database CLI:**
   ```bash
   pgcli --version
   usql --version
   iredis --version
   ```
