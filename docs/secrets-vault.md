# 🛡️ Quản Lý Bí Mật & Phiên Làm Việc (Secrets & Vault)

Tài liệu này mô tả chi tiết kiến trúc, danh mục các ứng dụng được quản lý, cơ chế mã hóa và cách vận hành của hệ thống bảo mật trong dotfiles.

---

## 1. Tổng Quan Kiến Trúc

Hệ thống bảo mật được chia thành 2 phân hệ độc lập:

| Phân hệ | File thực thi | Phạm vi quản lý | Định dạng lưu trữ | Mục đích chính |
| :--- | :--- | :--- | :--- | :--- |
| **Repo Secrets** | `scripts/secrets.sh` | Thư mục `secrets/` | `secrets.enc` (`age + zstd -9`) | Mã hóa file cấu hình tĩnh của repo (`.env`, khóa riêng tư API) |
| **Host Session Vault** | `scripts/vault.sh` | Thư mục `$HOME` | `secrets.vault` (`age + zstd -12`) | Sao lưu & khôi phục toàn bộ phiên đăng nhập, cookies, tokens của user |

---

## 2. Danh Sách Các Ứng Dụng Được Vault Quản Lý (`vault.sh`)

`vault.sh` chỉ tập trung sao lưu các phiên làm việc và thông tin xác thực quan trọng nhất của lập trình viên:

### A. Trình Duyệt Web & Master Keyring
1. **Google Chrome** (`~/.config/google-chrome`):
   - Toàn bộ hồ sơ người dùng (profiles), bookmarks, lịch sử.
   - Phiên đăng nhập web, session cookies và trạng thái xác thực 2 bước (2FA).
2. **GNOME Keyring** (`~/.local/share/keyrings`):
   - Cơ sở dữ liệu keyring hệ thống lưu trữ **Master Encryption Key**.
   - Bắt buộc phải có để giải mã cookies/mật khẩu an toàn của Chrome và Slack trên Linux.

### B. Ứng Dụng Trao Đổi Công Việc
3. **Telegram Desktop** (`~/.local/share/TelegramDesktop`):
   - Thư mục dữ liệu `tdata` chứa toàn bộ phiên làm việc của Telegram (không bị logout khi sang máy mới).
4. **Slack** (`~/.config/Slack`):
   - Token đăng nhập các workspace và trạng thái làm việc.
5. **Bytedance Lark / Feishu** (`~/.config/feishu`, `~/.local/share/feishu`, `~/.config/LarkShell`):
   - Thông tin xác thực và phiên làm việc của bộ ứng dụng Lark/Feishu.

### C. Khóa Bảo Mật & Thông Tin Xác Thực Lập Trình
6. **SSH Keys** (`~/.ssh`):
   - Khóa riêng tư (`id_ed25519`, `id_rsa`...), khóa công khai (`.pub`), file cấu hình `config` và `known_hosts`.
7. **GPG Keyring** (`~/.gnupg`):
   - Cặp khóa GPG cá nhân dùng để ký commit Git và cơ sở dữ liệu tín nhiệm (`trustdb`).
8. **GitHub CLI** (`~/.config/gh`):
   - Token xác thực tài khoản GitHub trong file `hosts.yml`.
9. **Git Identity & Config** (`~/.gitconfig`, `~/.config/git`):
   - Danh tính tác giả Git (name, email, signing key, aliases, URL routing cho tổ chức, global ignore).
10. **Docker Registry** (`~/.docker/config.json`):
    - Token xác thực đăng nhập Docker Hub và các Private Container Registries.
11. **Shell History** (`~/.zsh_history`):
    - Toàn bộ lịch sử các câu lệnh đã thực thi trên dòng lệnh.

### D. Trợ Lý AI & Công Cụ Lập Trình
12. **Antigravity Platform & IDE** (`~/.gemini`, `~/.antigravity-ide`, `~/.antigravity`):
    - Phiên đăng nhập tài khoản Google AI, cấu hình tiện ích và lịch sử hội thoại.
13. **9Router Gateway** (`~/.9router`):
    - Cấu hình proxy MITM và credentials phiên làm việc nội bộ.
14. **OpenAI Codex & ChatGPT Desktop** (`~/.codex`, `~/.config/ChatGPT`):
    - Phiên làm việc của OpenAI CLI và ứng dụng desktop ChatGPT.
15. **Postman** (`~/.config/Postman`):
    - Workspaces API, phiên làm việc và các biến môi trường kiểm thử.
16. **Beekeeper Studio** (`~/.config/beekeeper-studio`):
    - Danh sách kết nối cơ sở dữ liệu (PostgreSQL, MySQL, SQLite...) và mật khẩu đã lưu.

---

## 3. Các Ứng Dụng KHÔNG Đồng Bộ Qua Vault (Và Lý Do)

Để giữ cho file vault gọn gàng, bảo mật và tránh xung đột dữ liệu, các ứng dụng/dịch vụ sau được **loại bỏ khỏi phạm vi Vault**:

| Ứng dụng / Dịch vụ | Lý do loại bỏ khỏi Vault | Cơ chế quản lý thay thế |
| :--- | :--- | :--- |
| **Discord** | Không cần thiết lưu session cục bộ | Đăng nhập lại trực tiếp bằng QR/mật khẩu khi cần |
| **NPM Registry (`.npmrc`)** | Tránh lưu cứng token npm toàn cục | Cấu hình token theo từng project hoặc login trực tiếp |
| **OmniRoute** | Đã tinh giản hạ tầng AI, ưu tiên 9Router | Khởi tạo lại khi cần sử dụng multi-provider |
| **Agent Memory** | Dữ liệu ngữ cảnh AI agent độc lập | **Sẽ có cơ chế sao lưu / đồng bộ riêng biệt** |
| **Visual Studio Code** | Thường xuyên đồng bộ qua cloud | Sử dụng tính năng native **Settings Sync** của Microsoft/GitHub |
| **Obsidian** | Kho ghi chú Markdown cá nhân | Sử dụng Git repository riêng hoặc Obsidian Sync |
| **Jira & Jira CLI** | Tránh lưu trữ token doanh nghiệp lâu dài | Đăng nhập lại qua OAuth/API token khi bắt đầu sprint |
| **KDE Connect** | Phụ thuộc vào địa chỉ IP và mạng LAN | Quét mã QR ghép nối lại nhanh chóng trên thiết bị mới |

---

## 4. Danh Sách Các Thành Phần Bị Loại Trừ (Exclude Patterns)

Khi đóng gói các ứng dụng ở Mục 2, `vault.sh` tự động lọc bỏ các thư mục rác để tối ưu dung lượng:
- **Cache trình duyệt & Electron:** `Cache/*`, `Code Cache/*`, `GPUCache/*`, `Service Worker/*`, `Media Cache/*`, `DawnGraphiteCache/*`.
- **Dữ liệu mở rộng & model tạm:** `optimization_guide_model_store/*`, `google-chrome/*/Extensions/*`, `extensions_crx_cache/*`.
- **Báo cáo sự cố & metrics:** `Crashpad/*`, `BrowserMetrics/*`, `crashes/*`.
- **Runtime logs & lockfiles:** `*.log`, `logs/*`, `Singleton*`, `*.pid`, `*.sock`, `*.bak*`, `*.pre-*`.

---

## 5. Hướng Dẫn Câu Lệnh

```bash
# === REPO SECRETS (scripts/secrets.sh) ===
./scripts/secrets.sh encrypt   # Nén và mã hóa thư mục secrets/ thành secrets.enc
./scripts/secrets.sh decrypt   # Giải mã secrets.enc ra thư mục secrets/

# === USER SESSION VAULT (scripts/vault.sh) ===
# 1. Sao lưu toàn bộ phiên làm việc của user ra file vault
./scripts/vault.sh backup [duong-dan/secrets.vault]

# 2. Khôi phục toàn bộ phiên làm việc (Chrome, Slack, SSH, GPG, Tokens...)
./scripts/vault.sh restore [duong-dan/secrets.vault]

# 3. Xem danh sách các file/folder có trong file vault
./scripts/vault.sh list [duong-dan/secrets.vault]

# 4. Xóa session credentials cục bộ để kiểm tra khôi phục (có bước xác nhận an toàn)
./scripts/vault.sh clean [category|all]
```

