# 🚀 Workflow Lập Trình & Tiện Ích CLI (Git, Shell, Tools)

Tài liệu này mô tả chi tiết kiến trúc workflow dòng lệnh, cấu hình Git toàn cục, danh mục các công cụ CLI hiện đại viết bằng Rust/Go, và toàn bộ bảng tra cứu alias, phím tắt trong Zsh.

---

## 1. Cấu Hình Git Toàn Cục & Bảo Mật Danh Tính

### Kiến Trúc Bảo Mật Độc Lập
- Cấu hình Git (`~/.gitconfig`) và danh sách bỏ qua toàn cục (`~/.config/git/ignore`) được lưu trữ **dưới dạng file vật lý độc lập** tại `$HOME`.
- Các file này **không được commit vào Git công khai** để bảo mật tuyệt đối email, tên thật, GPG signing key và quy tắc routing nội bộ của doanh nghiệp.
- Toàn bộ được mã hóa và đồng bộ an toàn thông qua **[Host Session Vault](file:///home/loc/Workspaces/dotfiles/docs/secrets-vault.md)** (`./scripts/vault.sh`).

### Tính Năng Nổi Bật
- **Bộ hiển thị diff hiện đại `delta`:**
  - Tự động kích hoạt khi có gói `git-delta` (`GIT_PAGER="delta --dark --line-numbers --paging=auto"`).
  - Hiển thị diff dạng side-by-side hoặc inline với số dòng, highlight cú pháp theo ngôn ngữ, và git gutter rõ nét.
- **Tiêu chuẩn nhánh mặc định:** `init.defaultBranch = main`.
- **An toàn dòng kết thúc (Line Endings):** `core.autocrlf = input`.
- **Global Ignore:** Tự động loại bỏ file rác OS (`.DS_Store`, `Thumbs.db`), file tạm editor (`*.swp`, `*~`), cache AST (`.codegraph/`, `*.sqlite-shm`, `*.sqlite-wal`) và các file vault cục bộ (`secrets.vault`, `secrets.enc`).

### Bảng Phím Tắt Git Thường Dùng (Oh-My-Zsh Plugin)
| Phím tắt | Lệnh Git tương đương | Mục đích sử dụng |
| :--- | :--- | :--- |
| `gst` | `git status` | Xem trạng thái cây làm việc và file thay đổi |
| `ga .` / `gaa` | `git add .` / `git add --all` | Đưa file vào staging area |
| `gcmsg "..."` | `git commit -m "..."` | Tạo commit kèm thông điệp ngắn |
| `gp` | `git push` | Đẩy commit lên remote repository |
| `gl` | `git pull` | Kéo commit mới nhất từ remote về |
| `gco <branch>` | `git checkout <branch>` | Chuyển đổi giữa các nhánh |
| `gcb <branch>` | `git checkout -b <branch>` | Tạo nhánh mới và chuyển sang nhánh đó |
| `gb` | `git branch` | Liệt kê danh sách các nhánh |
| `gd` | `git diff` | Xem chi tiết thay đổi chưa stage qua `delta` |
| `gds` | `git diff --staged` | Xem thay đổi đã stage qua `delta` |
| `gsta` / `gstp` | `git stash push` / `pop` | Tạm cất / lấy lại thay đổi đang làm dở |
| `lg` | `lazygit` | Mở giao diện TUI quản lý Git trực quan |

---

## 2. Ma Trận Công Cụ Dòng Lệnh Hiện Đại (Rust / Go)

Hệ thống nâng cấp toàn bộ các công cụ UNIX truyền thống lên các phần mềm mã nguồn mở thế hệ mới viết bằng Rust hoặc Go, mang lại tốc độ tức thì và trải nghiệm dòng lệnh vượt bậc:

| Lệnh cũ | Lệnh hiện đại | Gói Arch (`pacman`) | Lệnh / Alias | Lợi ích & Tính năng nổi bật |
| :--- | :--- | :--- | :--- | :--- |
| `ls` | `eza` | `eza` | `ls`, `ll`, `la`, `lt` | Hiển thị màu sắc đẹp, phân loại icon, tích hợp Git status, cây thư mục trực quan |
| `cat` | `bat` | `bat` | `cat`, `catp` | Tô màu cú pháp (syntax highlighting), hiển thị số dòng, tích hợp Git gutter |
| `top` / `htop` | `bottom` | `bottom` | `bottom` (`btm`) | Giám sát CPU, RAM, Disk, Nhiệt độ, Mạng với đồ thị thời gian thực mượt mà |
| `git CLI` | `lazygit` | `lazygit` | `lg` | TUI quản lý Git: staging từng dòng (line-by-line), resolve merge conflict trực quan |
| `docker CLI`| `lazydocker` | `lazydocker` | `ld` | TUI quản lý Docker: xem streaming logs, quản lý container, images, volumes |
| `find` | `fd` | `fd` | `fd` | Tìm kiếm file siêu tốc, mặc định tự bỏ qua `.git` và file trong `.gitignore` |
| `grep` | `ripgrep` | `ripgrep` | `rg` | Tìm kiếm chuỗi văn bản trong toàn bộ codebase tốc độ mili-giây, bỏ qua file nhị phân |
| `rm -rf` | `trash-cli` | `trash-cli` | `rm`, `rmf` | Xóa an toàn đưa vào thùng rác (`~/.local/share/Trash`), `rmf` để xóa vĩnh viễn |
| `man` / `tldr` | `tealdeer` | `tealdeer` | `docs` (`tldr`) | Tra cứu cú pháp lệnh nhanh chóng (cheatsheet) với các ví dụ thực tế phổ biến nhất |
| `du -sh` | `dust` / `duf` | `dust`, `duf` | `du` / `df` | Phân tích trực quan đồ thị dung lượng ổ đĩa chiếm dụng theo dạng cây và bảng |
| `ping` | `gping` | `gping` | `ping` | Ping độ trễ mạng kèm biểu đồ trực tiếp dạng đồ họa ASCII trên terminal |
| `neofetch` | `fastfetch` | `fastfetch` | `fetch` | Hiển thị thông tin phần cứng và hệ điều hành tức thì bằng ngôn ngữ C |

---

## 3. Bảng Tra Cứu Toàn Diện Shell Aliases & Functions (`.zshrc`)

Toàn bộ cấu hình shell được tối ưu tại `modules/shell/files/.zshrc` (tự động symlink tới `~/.zshrc`):

### A. Điều Hướng Thư Mục (Navigation)
| Alias / Function | Lệnh thực thi | Mô tả |
| :--- | :--- | :--- |
| `..` | `cd ..` | Lùi lại 1 cấp thư mục |
| `...` | `cd ../..` | Lùi lại 2 cấp thư mục |
| `....` | `cd ../../..` | Lùi lại 3 cấp thư mục |
| `.....` | `cd ../../../..` | Lùi lại 4 cấp thư mục |
| `mkcd <dir>` | `mkdir -p <dir> && cd <dir>` | Tạo thư mục và tự động chuyển vào thư mục đó ngay lập tức |
| `z <tên-thư-mục>` | `zoxide` fuzzy jump | Nhảy nhanh tới bất kỳ thư mục nào đã từng truy cập |

### B. Trình Soạn Thảo & IDE (Editor & IDE Launchers)
| Alias | Lệnh thực thi | Mô tả |
| :--- | :--- | :--- |
| `n` / `v` | `nvim` | Khởi chạy Neovim |
| `n.` | `nvim .` | Mở Neovim tại thư mục hiện tại |
| `ide` / `code` | `antigravity-ide` | Khởi chạy Antigravity IDE (VS Code fork tối ưu AI) |
| `c.` / `code.` | `antigravity-ide .` | Mở Antigravity IDE tại dự án hiện tại |
| `c` | `clear` | Xóa sạch màn hình terminal |

### C. Clipboard, Mạng & Giám Sát Hệ Thống
| Alias | Lệnh thực thi | Mô tả |
| :--- | :--- | :--- |
| `cpwd` | `pwd \| tr -d '\n' \| wl-copy` | Copy đường dẫn thư mục hiện tại vào clipboard Wayland |
| `copy` | `wl-copy` | Copy dữ liệu đầu vào vào clipboard |
| `paste` | `wl-paste` | Dán dữ liệu từ clipboard ra terminal |
| `ports` | `sudo ss -tulpn \| grep LISTEN` | Liệt kê nhanh toàn bộ các cổng mạng (ports) đang lắng nghe |
| `myip` | `curl -s https://ifconfig.me` | Kiểm tra nhanh địa chỉ IP công khai |

### D. Quản Lý Dotfiles & Bí Mật (Dotfiles & Vault)
| Alias | Lệnh thực thi | Mô tả |
| :--- | :--- | :--- |
| `dots` | `cd "$DOTFILES_DIR"` | Nhảy nhanh về thư mục gốc của repository dotfiles |
| `vault-save` | `./scripts/vault.sh backup` | Sao lưu toàn bộ phiên làm việc, SSH, Git vào file vault |
| `vault-load` | `./scripts/vault.sh restore` | Khôi phục toàn bộ phiên làm việc từ file vault |
| `secrets-enc` | `./scripts/secrets.sh encrypt` | Mã hóa các biến môi trường và bí mật tĩnh trong repo |
| `secrets-dec` | `./scripts/secrets.sh decrypt` | Giải mã các file bí mật tĩnh trong repo |

### E. Tích Hợp File Manager & Giải Nén Nâng Cao
| Lệnh / Function | Cú pháp | Tính năng nổi bật |
| :--- | :--- | :--- |
| `y` / `yazi` | `y [path]` | TUI File manager siêu tốc `yazi`, tự động đổi `cd` của terminal khi thoát |
| `extract` | `extract <file>` | Tự động nhận diện định dạng nén (`.tar.gz`, `.tar.zst`, `.zip`, `.rar`, `.7z`...) và giải nén chuẩn xác |

---

## 4. Hướng Dẫn Cài Đặt Gói Cần Thiết

Tất cả các gói trên đã được khai báo chính thức tại [packages/pacman.txt](file:///home/loc/Workspaces/dotfiles/packages/pacman.txt). Để cài đặt đồng loạt:

```bash
sudo pacman -S --needed eza bat bottom lazygit lazydocker trash-cli tealdeer dust duf gping git-delta fastfetch
```
Hoặc chạy lệnh setup chuẩn của repository:
```bash
./install.sh
```
Sau khi cài đặt xong, bạn chỉ cần nạp lại shell:
```bash
source ~/.zshrc
```
