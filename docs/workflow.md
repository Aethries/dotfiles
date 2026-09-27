# 🚀 Workflow Dự Án & Tiện Ích CLI (`pj`, Git, Tools)

Tài liệu này mô tả các công cụ tăng tốc năng suất lập trình, công cụ chuyển đổi dự án siêu tốc `pj`, cấu hình Git toàn cục và danh mục các công cụ CLI hiện đại.

---

## 1. Công Cụ Chuyển Project Siêu Tốc (`pj`)

- **Vị trí file:** `scripts/pj.sh` (được symlink tới `~/.local/bin/pj`).
- **Mục đích:** Giúp bạn nhảy ngay tới bất kỳ project nào trong các thư mục `~/Workspaces`, `~/Projects`, `~/Repos`, `~/src` chỉ với vài ký tự.

### Cách thức hoạt động:
1. Bạn gõ `pj` trong terminal.
2. Một giao diện `fzf` toàn màn hình xuất hiện với danh sách toàn bộ repositories.
3. Bên phải là khung **Live Preview** tức thì:
   - Nếu là Git repo: hiển thị `git status -s` và 5 commits gần nhất.
   - Nếu là thư mục thường: hiển thị cây thư mục qua `eza --tree`.
4. **Các phím tắt hành động linh hoạt:**
   - **`Enter`**: Tạo hoặc gắn vào session **Zellij** mang tên của project đó.
   - **`Ctrl + A`** hoặc **`Ctrl + O`**: Mở project bằng **Antigravity IDE**.
   - **`Ctrl + N`**: Mở project bằng **Neovim**.
   - **`Ctrl + G`**: Mở project bằng **Lazygit**.
   - **`Ctrl + Y`**: Mở project bằng trình duyệt file **Yazi**.

---

## 2. Cấu Hình Git Toàn Cục (`.gitconfig` & `ignore`)

- Cấu hình đặt tại `~/.gitconfig` và file bỏ qua toàn cục `~/.config/git/ignore`.
- **Tính năng nổi bật:**
  - Tích hợp công cụ hiển thị diff màu hiện đại **`delta`** (side-by-side hoặc inline diff với cú pháp nổi bật).
  - Tự động cấu hình chuẩn nhánh mặc định (`init.defaultBranch = main`).
  - Hỗ trợ Git LFS (Large File Storage).
  - Tự động bỏ qua các file rác của hệ điều hành (`.DS_Store`, `Thumbs.db`, `.swp`, `*.bak`).

---

## 3. Bộ Công Cụ Dòng Lệnh Hiện Đại

Hệ thống thay thế các lệnh UNIX truyền thống bằng các công cụ viết bằng Rust/Go hiệu năng cao:

| Lệnh cũ | Lệnh hiện đại | Gói cài đặt | Lợi ích |
| :--- | :--- | :--- | :--- |
| `ls` | `eza --icons` | `eza` | Hiển thị màu sắc đẹp, phân loại icon, cây thư mục trực quan |
| `cat` | `bat` | `bat` | Tô màu cú pháp (syntax highlighting), tích hợp Git gutter |
| `top` / `htop` | `bottom` (`btm`) | `bottom` | Giám sát CPU, RAM, Disk, Mạng với đồ thị thời gian thực |
| `git CLI` | `lazygit` (`lg`) | `lazygit` | Giao diện TUI quản lý Git, staging từng dòng, resolve conflicts |
| `docker CLI`| `lazydocker` (`ld`)| `lazydocker` | Giao diện TUI xem logs, quản lý containers, images, volumes |
| `find` | `fd` | `fd` | Tìm kiếm file siêu tốc, tự động bỏ qua thư mục `.git` |
| `grep` | `rg` | `ripgrep` | Tìm chuỗi văn bản trong toàn bộ codebase tốc độ mili-giây |
| `rm -rf` | `trash` | `trash-cli` | Xóa an toàn đưa vào thùng rác thay vì xóa vĩnh viễn |
| `man` / `tldr` | `tldr` | `tealdeer` | Cheatsheet câu lệnh nhanh viết bằng Rust |
| `du -sh` | `dust` / `duf` | `dust`, `duf` | Phân tích trực quan thư mục nào đang chiếm nhiều dung lượng ổ đĩa |
| `ping` | `gping` | `gping` | Ping mạng vẽ đồ thị trực tiếp trên dòng lệnh |
