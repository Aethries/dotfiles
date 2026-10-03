# Kế hoạch 12: Hệ Sinh Thái Modern Shell, Terminal & CLI Workstation Tooling

## 1. Tên chức năng
**Nâng Cấp Hệ Sinh Thái Terminal & Bộ Công Cụ CLI Hiện Đại (Lazydocker, Bat, Superfile, Delta, Monitoring & Data Wrangling).**

---

## 2. Mô tả chức năng

### 2.1. Vấn đề hiện tại
* Công việc hằng ngày trên workstation cần thao tác nhiều với container Docker, kiểm tra logs, xem diff Git, duyệt file TUI, giám sát tài nguyên và phân tích dữ liệu dạng JSON/YAML.
* Các lệnh truyền thống của GNU Coreutils (`cat`, `ls`, `find`, `grep`, `df`, `du`, `ps`) thiếu màu sắc, không hỗ trợ syntax highlighting, không tích hợp Git status và hiển thị dữ liệu thô khó đọc.
* Chưa có TUI tương tác mạnh mẽ cho Docker (`lazydocker`) để thao tác nhanh với containers, logs, stats mà không cần gõ lệnh dài.
* Các công cụ hiện đại cần được cấu hình đồng bộ phông chữ (`JetBrains Mono Nerd Font`), bảng màu (`Noctalia Theme`), phím tắt và alias trong Zsh.

### 2.2. Mục tiêu kỹ thuật
1. **Container Management**:
   * Tích hợp `lazydocker`: Quản lý Docker containers, images, volumes, logs bằng giao diện TUI trực quan.
   * Cung cấp alias `ld`, gán quyền socket Docker không cần sudo (`docker` group).
2. **File & Content Inspection**:
   * `bat`: Thay thế `cat` với syntax highlighting, số dòng, Git gutter và tích hợp Noctalia/Gruvbox theme.
   * `eza`: Thay thế `ls` với icons Nerd Font, cây thư mục, quyền file và trạng thái Git.
   * `superfile` & `yazi`: Bộ đôi TUI file manager dual-pane, xem trước ảnh, syntax code, đồng bộ theme Noctalia.
   * `zoxide`: Điều hướng thư mục thông minh (`z <tên>`).
3. **Diff & Git Tooling**:
   * `git-delta`: Pager phân tích cú pháp Git diff / log với side-by-side, syntax highlighting.
   * `lazygit`: TUI Git client tốc độ cao (đã có Noctalia theme).
   * `onefetch`: Hiển thị tóm tắt repo và ngôn ngữ lập trình dạng đồ họa ASCII.
4. **Hệ thống & Tài nguyên (Monitoring & Diagnostics)**:
   * `bottom` (`btm`) & `btop`: Giám sát CPU, RAM, Network, GPU, Disk, Processes theo biểu đồ thời gian thực.
   * `dust`: Trực quan hóa dung lượng ổ đĩa dạng cây đồ họa thay cho `du`.
   * `duf`: Hiển thị bảng phân vùng ổ đĩa rõ ràng thay cho `df`.
   * `procs`: Quản lý tiến trình có màu sắc, thông tin cổng mạng, CPU/RAM chi tiết thay cho `ps`.
   * `gping`: Ping mạng hiển thị biểu đồ đồ họa thời gian thực.
5. **Data Wrangling & API Inspection**:
   * `jq` & `yq`: Bộ lọc và định dạng JSON / YAML.
   * `fx`: Terminal JSON viewer có khả năng collapse/expand và tương tác bàn phím.
   * `curlie` / `httpie`: HTTP client với cú pháp thân thiện, output tự động format JSON có màu.
6. **Documentation & Tra cứu nhanh**:
   * `tealdeer` (`tldr`): Tra cứu nhanh cú pháp lệnh với ví dụ thực chiến (viết bằng Rust siêu tốc).

---

## 3. Danh mục gói phần mềm (Packages)

### 3.1. Arch Linux Pacman (`packages/pacman.txt`)
```text
# Terminal Core & Navigation
zsh
fzf
ripgrep
fd
zoxide
eza
bat
superfile
yazi

# Git & Containers
lazygit
lazydocker
git-delta

# System & Monitoring
bottom
dust
duf
gping
tealdeer
procs

# Data & Processing
jq
yq
```

### 3.2. AUR Packages (`packages/aur.txt`)
```text
fx
onefetch
curlie
```

---

## 4. Chi tiết triển khai

### 4.1. Cấu hình Lazydocker (`~/.config/lazydocker/config.yml`)
* Tạo file `modules/shell/files/lazydocker/config.yml`:
```yaml
gui:
  scrollHeight: 2
  theme:
    activeBorderColor:
      - "#b8bb26" # Noctalia primary
      - bold
    inactiveBorderColor:
      - "#665c54"
    optionsTextColor:
      - "#83a598"
    selectedLineBgColor:
      - "#3c3836"
stats:
  graphs:
    - min: 0
      max: 100
      height: 10
      caption: "CPU (%)"
      statPath: "DerivedStats.CPUPercentage"
    - min: 0
      max: 100
      height: 10
      caption: "Memory (%)"
      statPath: "DerivedStats.MemoryPercentage"
```

### 4.2. Cấu hình Bat (`~/.config/bat/config`)
* Tạo file `modules/shell/files/bat/config`:
```text
--theme="gruvbox-dark"
--style="numbers,changes,header"
--italic-text=always
--paging=auto
--map-syntax "*.kdl:C++"
--map-syntax "*.rasi:CSS"
```

### 4.3. Cấu hình Delta trong Git (`modules/git/files/.gitconfig`)
```ini
[core]
    pager = delta

[interactive]
    diffFilter = delta --color-only

[delta]
    navigate = true
    light = false
    line-numbers = true
    side-by-side = false
    syntax-theme = gruvbox-dark
    plus-style = syntax "#1d3b24"
    minus-style = syntax "#3f1e1e"
    line-numbers-left-format = "{nm:>4}┊"
    line-numbers-right-format = "{np:>4}│"
```

### 4.4. Tích hợp Shell Setup (`modules/shell/setup.sh`)
* Tạo thư mục `modules/shell/files/lazydocker` và `modules/shell/files/bat`.
* Bổ sung symlink:
  * `~/.config/lazydocker/config.yml` -> `modules/shell/files/lazydocker/config.yml`
  * `~/.config/bat/config` -> `modules/shell/files/bat/config`

---

## 5. Hướng dẫn sử dụng & Phím tắt

| Lệnh / Phím tắt | Công cụ | Mục đích sử dụng |
|---|---|---|
| `ld` | `lazydocker` | Mở TUI quản lý Docker container, logs, restart, inspect |
| `lg` | `lazygit` | Mở TUI Git stage/commit/rebase/stash |
| `cat <file>` | `bat` | Xem nội dung file có số dòng, highlight code, git diff |
| `ls`, `ll`, `la`, `lt` | `eza` | Liệt kê file với icon, git status, xem cây thư mục |
| `z <dir>` | `zoxide` | Nhảy nhanh tới thư mục thường dùng mà không cần gõ full path |
| `spf` | `superfile` | Mở TUI file manager dual-pane hiện đại (Noctalia theme) |
| `y` / `yazi` | `yazi` | File manager siêu tốc, tự động cd khi thoát |
| `bottom` / `btm` | `bottom` | Mở bảng theo dõi CPU, RAM, Disk, Mạng |
| `du` | `dust` | Hiển thị đồ thị cây dung lượng thư mục |
| `df` | `duf` | Bảng trực quan hóa các phân vùng ổ đĩa |
| `ping <host>` | `gping` | Kiểm tra độ trễ mạng với đồ thị thời gian thực |
| `docs <cmd>` | `tealdeer` | Tra cứu nhanh ví dụ thực chiến của lệnh CLI |
| `fx <file.json>` | `fx` | Duyệt JSON dạng cây tương tác |

---

## 6. Kiểm thử nghiệm thu (Acceptance Criteria)
1. Lệnh `ld` khởi động ngay `lazydocker` kết nối tới Docker daemon, màu viền theo Noctalia.
2. Lệnh `cat` chạy `bat` hiển thị code có syntax highlighting chuẩn font JetBrains Mono.
3. Lệnh `spf` mở `superfile` với giao diện bo góc, theme `noctalia`, icon Nerd Font đầy đủ.
4. Lệnh `git diff` tự động dùng `delta` với số dòng và màu sắc phân biệt rõ ràng.
5. FZF nhận biến `FZF_DEFAULT_OPTS` từ `~/.config/fzf/themes/noctalia.sh` khi bấm `Ctrl+R` hoặc `Ctrl+T`.
