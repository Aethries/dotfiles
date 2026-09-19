# Core Architectural Guidelines & Sync Boundary

Tài liệu này xác định **nguyên tắc kiến trúc cốt lõi và ranh giới đồng bộ (Sync Boundary)** của toàn bộ dự án dotfiles, dựa trên chuẩn hóa từ `DOTFILES_MAIN_FINAL_REVIEW_AND_FIX_PLAN.md`.

---

## 1. Phân tách ranh giới đồng bộ (Sync Boundary)

### 1.1. Repository ĐỒNG BỘ (Portable Desired State)
Những thành phần thuộc cấu hình mong muốn dùng chung cho môi trường làm việc chuẩn hóa, có thể tái lập trên mọi workstation:
- **Khai báo hệ thống & công cụ phát triển:** Cấu hình NixOS, gói phần mềm, terminal, shell (`modules/`).
- **Cấu hình ứng dụng dùng chung:** Niri, Noctalia, Kitty, Zellij, Neovim, Zsh, Starship, Fcitx (`resources/`).
- **Scripts tự động hóa & orchestration:** Các script build, preflight, doctor, bootstrap (`scripts/`).
- **Năng lực workstation di động:** Docker, PipeWire, KDE Connect, Bluetooth.
- **AI Gateways (9Router & OmniRoute):**
  - Cổng dịch vụ chuẩn hóa (9Router: 20128, OmniRoute: 20129).
  - Cấu hình template service, systemd user units.
  - DNS host mappings phục vụ MITM routing (`networking.extraHosts`).
  - Chứng chỉ CA công khai (`resources/certs/9router-rootCA.crt`).
  - Biến môi trường mặc định không nhạy cảm (`resources/ai/gateway.env`).
- **Lockfiles & Checksums:** Extension lockfile, plugin hash, derivation locks (`flake.lock`).
- **Tùy biến giao diện & locale chuẩn:** Thống nhất cho mọi máy cài đặt.

### 1.2. Repository TUYỆT ĐỐI KHÔNG ĐỒNG BỘ (Machine Identity & Private State)
Những thông tin và trạng thái gắn liền với máy vật lý cụ thể, cấm commit vào git:
- **Định danh máy & người dùng:** Hostname, username cá nhân (ví dụ: `loc`), mật khẩu user, Wi-Fi SSID/passwords.
- **Phần cứng vật lý:** File `hardware-configuration.nix`, UUID phân vùng ổ đĩa, bảng phân vùng GPT.
- **Chính sách lưu trữ & bộ nhớ ảo:** Swap partition, swapfile dung lượng cố định (phụ thuộc RAM máy vật lý).
- **Driver & phần cứng chuyên biệt:** Intel Media Driver, AMD/Nvidia GPU drivers, tham số kernel riêng (`usbcore.autosuspend`, `hid_apple.fnmode`), udev rules cho thiết bị cụ thể (WEIKAV keyboard).
- **Bộ nạp khởi động (Bootloader):** Cấu hình `systemd-boot`/GRUB, biến EFI riêng của bo mạch chủ.
- **Nền tảng vòng đời hệ thống:** `system.stateVersion` (phiên bản cài đặt ban đầu của từng máy).
- **Khóa bí mật & cơ sở dữ liệu cục bộ:**
  - Private key của 9Router Root CA (`9router-rootCA-key.pem`).
  - `STORAGE_ENCRYPTION_KEY` của OmniRoute.
  - Database SQLite nội bộ (`storage.sqlite`, browser cookies, app sessions).
  - SSH private keys, Age private keys.

---

## 2. Quy tắc quyết định (Decision Rule)

Khi tạo hoặc sửa bất kỳ thiết lập cấu hình nào, áp dụng sơ đồ quyết định sau:

```text
Cấu hình này có gắn liền với phần cứng máy vật lý cụ thể không?
    │
    ├── CÓ  ──> Đưa vào .machine/ hoặc local state (gitignored).
    │
    └── KHÔNG ──> Tính năng dùng chung có bắt buộc cần không?
                    │
                    ├── CÓ  ──> Đưa vào cấu hình khai báo của Repo (tracked).
                    └── KHÔNG ──> Giữ ở local / tùy chọn (opt-in).
```

---

## 3. Nguyên tắc vận hành (Operational Principles)

### 3.1. Zero-Touch Bootstrap
Khi sang một máy mới, chỉ cần chạy một lệnh duy nhất:
```bash
./scripts/bootstrap.sh
# hoặc trên Live ISO:
sudo ./scripts/nixos-installer.sh
```
- Tự động phát hiện môi trường, kiểm tra preflight.
- Tự động sinh trạng thái `.machine/` tương thích với phần cứng và user hiện tại.
- Tự động tạo symlink cấu hình và nạp systemd units.
- Tự động điều hòa (reconcile) AI gateways và kích hoạt dịch vụ mà không cần cấu hình thủ công.

### 3.2. Không Hardcode (Zero Hardcoding)
- Tuyệt đối không hardcode username cá nhân (như `loc`), đường dẫn `$HOME` cố định trong các Nix modules hoặc shell scripts dùng chung.
- Mọi module chung phải sử dụng biến động hoặc nhận tham số từ cấu hình `.machine/`.

### 3.3. Tính bất biến khi chạy lại (Idempotency)
- Mọi script (`bootstrap.sh`, `init-9router.sh`, `reconcile-ai-gateways.sh`, `build.sh`) phải an toàn tuyệt đối khi chạy nhiều lần liên tiếp.
- Tự động phục hồi drift, không bao giờ ghi đè làm mất dữ liệu người dùng (`safe_link` phải kiểm tra nguồn trước khi symlink).

### 3.4. An toàn bảo mật tuyệt đối (Zero-Leak Security)
- Mọi dữ liệu nhạy cảm được mã hóa qua Age (`secrets.vault` hoặc `secrets.enc`).
- Tuyệt đối không để lọt plaintext secret, private keys vào commit lịch sử của git.

---

## 4. Kiến trúc hệ thống mục tiêu (Target Architecture)

```text
dotfiles/
├── flake.nix
├── flake.lock
├── configuration.nix
│
├── modules/
│   ├── base.nix
│   ├── packages.nix
│   ├── desktop.nix
│   ├── fonts.nix
│   ├── i18n.nix
│   ├── shell.nix
│   ├── nvim.nix
│   ├── lsp.nix
│   ├── godot.nix
│   ├── zellij.nix
│   │
│   ├── services/
│   │   ├── containers.nix
│   │   ├── audio.nix
│   │   ├── desktop-services.nix
│   │   └── ai-gateways.nix
│   │
│   └── hardware/
│       ├── intel-graphics.nix
│       └── weikav-nut75.nix
│
├── resources/
│   ├── ai/
│   │   └── gateway.env
│   ├── certs/
│   │   └── 9router-rootCA.crt
│   └── ...
│
├── scripts/
│   ├── bootstrap.sh
│   ├── preflight.sh
│   ├── build.sh
│   ├── doctor.sh
│   ├── reconcile-ai-gateways.sh
│   ├── init-9router.sh
│   ├── init-omniroute.sh
│   └── lib/
│       ├── common.sh
│       ├── target-user.sh
│       ├── machine.sh
│       └── links.sh
│
├── tests/
│   ├── bootstrap/
│   ├── installer/
│   ├── ai/
│   ├── vault/
│   └── zellij/
│
└── .machine/                    # GITIGNORED - Machine Local State
    ├── configuration.nix
    ├── hardware-configuration.nix
    ├── hardware-extra.nix
    └── identity.nix
```

---

## 5. Chuẩn mực AI Gateways & Mạng

1. **Độc quyền ghi `/etc/hosts`:**
   Chỉ NixOS sở hữu khai báo `networking.extraHosts`. Các script như `init-9router.sh` cấm sửa trực tiếp `/etc/hosts`.
2. **Khóa phiên bản (Version Pinning):**
   Cấm sử dụng `@latest` cho các dependencies như `9router`. Phiên bản phải được ghim cố định trong `resources/ai/gateway.env`.
3. **Quản lý chứng chỉ Root CA:**
   Chứng chỉ công khai (`.crt`) được commit và quản lý qua `security.pki.certificateFiles`. Private key lưu trữ cục bộ/vault.
4. **Cô lập Loopback:**
   Cổng 9Router (20128) và OmniRoute (20129) chỉ bind loopback nội bộ `127.0.0.1`, không phơi bày ra mạng ngoài.

---

## 6. Tiêu chí hoàn thành (Definition of Done & QA Gates)

Mỗi thay đổi phải vượt qua toàn bộ các cổng kiểm tra trước khi hợp nhất vào `main`:
1. **QA tĩnh:**
   - `shellcheck` không có cảnh báo.
   - `nixfmt --check` đạt chuẩn.
   - `nix flake check` đánh giá hợp lệ.
   - `systemd-analyze verify` cho user units.
2. **Kiểm thử tích hợp:**
   - Kiểm thử cô lập cấu hình (`test-isolated.sh`).
   - Kiểm thử mock fresh installer và bootstrap.
   - Doctor kiểm tra pass 100% các chỉ số sức khỏe.
3. **Ranh giới bất biến:**
   - Không chứa bất kỳ username cá nhân nào trong `modules/`.
   - Không chứa cấu hình phần cứng cụ thể trong các module toàn cục.
