# Kế hoạch 06: Quản lý Runtime Đa Ngôn Ngữ Hiện Đại (`mise`) và Python Siêu Tốc (`uv`)

## 1. Tên chức năng
**Hợp Nhất Quản Trị Runtime Đa Ngôn Ngữ Bằng `mise-en-place` và Tối Ưu Hóa Môi Trường Python Bằng `uv`.**

---

## 2. Mô tả chức năng

### 2.1. Vấn đề hiện tại
* Hệ thống hiện tại đang sử dụng `nvm` cho Node.js. NVM là một shell function cồng kềnh, làm chậm đáng kể thời gian khởi động Zsh mỗi khi mở tab terminal mới (overhead khoảng 200-400ms).
* Chưa có công cụ quản lý phiên bản cho các ngôn ngữ khác: Python (hiện chỉ có Python của hệ thống, dễ gây vỡ package hệ thống nếu dùng `sudo pip`), Rust, Go, Bun và công cụ IaC như OpenTofu/Terraform.
* Quản lý phân mảnh: Nếu cài đặt nhiều công cụ rời rạc (`nvm`, `pyenv`, `rustup`, `gvm`, `poetry`), việc đồng bộ biến môi trường `PATH` sẽ rất rối rắm.
* Quá trình cài đặt thư viện Python bằng `pip` và tạo virtual environment bằng `venv` truyền thống diễn ra chậm chạp và tốn dung lượng ổ đĩa.

### 2.2. Mục tiêu kỹ thuật
1. **Loại bỏ NVM**, thay thế hoàn toàn bằng **`mise`** (`mise-en-place`):
   * Viết bằng Rust, tốc độ shim cực nhanh (gần như 0ms overhead).
   * Quản lý tập trung mọi runtime trong một file cấu hình duy nhất: Node.js, Python, Rust, Go, Bun, Terraform/OpenTofu, pnpm.
   * Tự động nhận diện và switch version theo file dự án: `.mise.toml`, `.tool-versions`, `package.json`, `.python-version`.
2. **Tích hợp `uv` cho hệ sinh thái Python**:
   * Package manager và project manager viết bằng Rust của Astral.
   * Tạo virtual environment trong **~10 mili-giây** và tải/cài đặt thư viện nhanh gấp **10 - 100 lần** so với `pip`.
   * Quản lý các công cụ CLI độc lập an toàn qua `uv tool` (thay thế hoàn hảo cho `pipx`).

---

## 3. Chi tiết triển khai

### 3.1. Các file cần tạo và sửa đổi

* **[MODIFY]** [packages/pacman.txt](file:///home/loc/Workspaces/dotfiles/packages/pacman.txt):
  * **Xóa:** `nvm`.
  * **Thêm:** `mise`, `uv`.
* **[NEW]** `modules/mise/files/config.toml`: File cấu hình runtime mặc định toàn cục (`~/.config/mise/config.toml`).
* **[NEW]** `modules/mise/setup.sh`: Script cài đặt symlink cấu hình và cài đặt sẵn các tool toàn cục cốt lõi.
* **[MODIFY]** [modules/shell/files/.zshrc](file:///home/loc/Workspaces/dotfiles/modules/shell/files/.zshrc):
  * Gỡ bỏ đoạn `source /usr/share/nvm/init-nvm.sh`.
  * Thêm dòng kích hoạt: `eval "$(mise activate zsh)"`.
* **[MODIFY]** [install.sh](file:///home/loc/Workspaces/dotfiles/install.sh): Thay thế bước gọi `modules/node/setup.sh` bằng `modules/mise/setup.sh`.

### 3.2. Cấu hình chi tiết `modules/mise/files/config.toml`

```toml
# ~/.config/mise/config.toml
[tools]
node = "lts"
python = "3.12"
rust = "latest"
go = "latest"
bun = "latest"
pnpm = "latest"
opentofu = "latest"

[settings]
legacy_version_file = true
experimental = true
jobs = 4
```

---

## 4. Hướng dẫn sử dụng

### 4.1. Quản lý Runtime dự án với `mise`

```bash
# Xem danh sách các phiên bản runtime đang được kích hoạt
mise current

# Cài đặt phiên bản Node.js hoặc Python cho dự án hiện tại (tạo file .mise.toml cục bộ)
mise use node@22
mise use python@3.11

# Cài đặt phiên bản toàn cục (Global)
mise use -g node@lts

# Cập nhật tất cả các runtime lên phiên bản mới nhất
mise upgrade

# Chạy một lệnh với phiên bản runtime cụ thể mà không cần cài lâu dài
mise exec node@18 -- npm test
```

### 4.2. Thao tác siêu tốc với `uv` cho Python

```bash
# 1. Khởi tạo một dự án Python mới
uv init my-project
cd my-project

# 2. Tạo virtual environment tức thì (~10ms)
uv venv

# 3. Cài đặt thư viện với tốc độ tên lửa (hỗ trợ lockfile uv.lock)
uv add fastapi uvicorn requests

# 4. Chạy script hoặc service tự động trong môi trường venv
uv run uvicorn main:app --reload

# 5. Cài đặt các công cụ CLI độc lập mà không làm bẩn hệ thống (thay thế pipx)
uv tool install ruff
uv tool install black
uv tool install httpie
```

---

## 5. Tiêu chuẩn kiểm thử & Nghiệm thu (Verification)

1. **Kiểm tra thời gian mở Shell:**
   ```bash
   time zsh -i -c exit
   # Thời gian khởi động shell phải < 100ms (giảm mạnh so với khi còn dùng NVM)
   ```
2. **Kiểm tra `mise` hoạt động:**
   ```bash
   node -v
   python --version
   go version
   # Các lệnh phải trỏ về shim của mise (~/.local/share/mise/shims/...)
   ```
3. **Kiểm tra tốc độ của `uv`:**
   ```bash
   uv venv /tmp/test-venv
   # Thời gian tạo venv phải hoàn thành trong tích tắc (< 50ms)
   ```
