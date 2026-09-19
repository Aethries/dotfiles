# Vault Security & Secrets Management

Tài liệu này xác định quy chuẩn bảo mật và quản lý thông tin nhạy cảm trong repository dotfiles, dựa trên công cụ Age và kịch bản `scripts/secrets.sh`.

---

## 1. Nguyên tắc cốt lõi: Zero-Leak Security

1. **Tuyệt đối không commit plaintext:** Không bao giờ commit bất kỳ khóa API, private key, mật khẩu, Wi-Fi profile hoặc token nào vào git.
2. **Phân loại rõ ràng:**
   - `secrets/`: Thư mục chứa dữ liệu plaintext làm việc cục bộ, **luôn luôn nằm trong `.gitignore`**.
   - `secrets.vault`: Bản sao lưu toàn phần (Full-State Encrypted Backup) của máy cục bộ (bao gồm SQLite DB của OmniRoute, cookie trình duyệt, credentials). **Luôn luôn nằm trong `.gitignore`**.
   - `secrets.enc` (hoặc `secrets.age`): File lưu trữ thông tin bí mật đã mã hóa bằng passphrase qua Age, chỉ được commit khi dự án có nhu cầu đồng bộ bí mật mã hóa di động có chủ đích.

---

## 2. Công cụ mã hóa & thao tác

Sử dụng script `./scripts/secrets.sh`:

### 2.1. Mã hóa bí mật làm việc
```bash
./scripts/secrets.sh encrypt
```
- Nén toàn bộ thư mục `secrets/` thành file mã hóa an toàn bằng Age với mật khẩu khóa (passphrase).
- Tạo file `secrets.enc`.

### 2.2. Giải mã khi bootstrap máy mới
```bash
./scripts/secrets.sh decrypt
```
- Nhập mật khẩu để giải mã `secrets.enc` về lại thư mục `secrets/`.
- Phục hồi các file khóa môi trường và API keys cần thiết cho máy trạm.

---

## 3. Quản lý AI Gateway Credentials

### 3.1. 9Router
- **Public Root CA:** File `resources/certs/9router-rootCA.crt` được commit vào repository để phục vụ MITM certificate pinning.
- **Private CA Key:** File `9router-rootCA-key.pem` thuộc trạng thái nhạy cảm cục bộ, tuyệt đối không commit vào git, được lưu trong `secrets/` hoặc sinh tự động cục bộ khi init.

### 3.2. OmniRoute
- **Cơ sở dữ liệu:** File `storage.sqlite` chứa lịch sử, tokens, và cấu hình provider cục bộ. Cấm commit vào git.
- **Khóa mã hóa:** Biến `STORAGE_ENCRYPTION_KEY` sinh ngẫu nhiên khi bootstrap và lưu trong `secrets/omniroute.env`.
- **Sao lưu phục hồi:** Sử dụng `sync-omniroute backup` để nạp trạng thái vào `secrets.vault`.
