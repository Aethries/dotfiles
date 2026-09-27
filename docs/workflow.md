# 🚀 Workflow Lập Trình & Tiện Ích CLI (Git, Tools)

Tài liệu này mô tả cấu hình Git toàn cục và danh mục các công cụ CLI hiện đại giúp tối ưu hóa hiệu suất làm việc dòng lệnh.

---

## 1. Cấu Hình Git Toàn Cục (`.gitconfig` & `ignore`)

- Cấu hình đặt tại `~/.gitconfig` và file bỏ qua toàn cục `~/.config/git/ignore`.
- **Tính năng nổi bật:**
  - Tích hợp công cụ hiển thị diff màu hiện đại **`delta`** (side-by-side hoặc inline diff với cú pháp nổi bật).
  - Tự động cấu hình chuẩn nhánh mặc định (`init.defaultBranch = main`).
  - Hỗ trợ Git LFS (Large File Storage).
  - Tự động bỏ qua các file rác của hệ điều hành (`.DS_Store`, `Thumbs.db`, `.swp`, `*.bak`).

---

## 2. Bộ Công Cụ Dòng Lệnh Hiện Đại

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
