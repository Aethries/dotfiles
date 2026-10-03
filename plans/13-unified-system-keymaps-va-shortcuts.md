# Kế hoạch 13: Chuẩn Hóa và Đồng Bộ Hệ Thống Phím Tắt Toàn Cục (Unified Keymaps)

## 1. Tên chức năng
**Hệ Thống Phím Tắt Toàn Cục Nhất Quán (Compositor, Terminal, Multiplexer, IDE, Editor & TUI).**

---

## 2. Mô tả chức năng

### 2.1. Vấn đề hiện tại
* Phím tắt trên hệ thống đang phân mảnh và có nguy cơ xung đột:
  * Compositor (Umbriel) dùng `Mod` (Super).
  * Terminal Multiplexer (Zellij) dùng `Ctrl+o` hoặc `Alt`.
  * IDE (VS Code, Antigravity) và Editors (Neovim) có thói quen phím tắt riêng.
  * Bộ gõ tiếng Việt Fcitx5 Bamboo dễ bị nuốt phím khi kết hợp các modifier keys.
* Thiếu một bản đồ tư duy phím tắt chuẩn (Mental Model) để người dùng chuyển đổi mượt mà giữa các tầng ứng dụng mà không cần ghi nhớ hàng chục tổ hợp phím rời rạc.

### 2.2. Mô hình phân tầng phím tắt (Keymap Hierarchy Mental Model)

| Tầng (Layer) | Phím bổ trợ chính | Phạm vi điều khiển | Ví dụ điển hình |
|---|---|---|---|
| **1. System / Window** | `Mod` (Super / Win) | Compositor Umbriel, Desktop Shell Noctalia, Launcher, Workspaces, Monitor | `Mod+Space` (Launcher), `Mod+Q` (Close), `Mod+1..9` (Workspace) |
| **2. Multiplexer & Split** | `Alt` | Phân chia panel trong Kitty / Zellij, chuyển đổi split panes | `Alt+h/j/k/l` (Focus pane), `Alt+n` (New pane), `Alt+w` (Close pane) |
| **3. Editor Modal** | `Leader` (`Space`) | Neovim normal mode navigation, file finder, LSP actions, git diff | `<leader>ff` (Find file), `<leader>e` (File explorer), `<leader>ca` (Code action) |
| **4. App Internal** | `Ctrl` / `Ctrl+Shift` | Thao tác bên trong app (VS Code, Antigravity, Chrome, Terminal apps) | `Ctrl+P` (Quick open), `Ctrl+\`` (Terminal toggle), `Ctrl+S` (Save) |
| **5. Kernel Remap** | `CapsLock` | Tầng kernel qua Kanata (Home-row mods, Dual-role key) | Tap `CapsLock` = `Escape`, Hold `CapsLock` = `Ctrl` |
| **6. Mouse Navigation** | `Mod+X` | Điều khiển chuột bằng bàn phím qua `warpd` | `Mod+X` (Hint mode nhảy chuột không cần chạm touchpad/chuột) |

---

## 3. Chi tiết triển khai

### 3.1. Các file cấu hình liên quan
* [modules/umbriel/files/keybinds.toml](file:///home/loc/Workspaces/dotfiles/modules/umbriel/files/keybinds.toml): Phím tắt window, workspace, OSD, launcher.
* [modules/zellij/files/config.kdl](file:///home/loc/Workspaces/dotfiles/modules/zellij/files/config.kdl): Phím tắt điều hướng pane/tab theo chuẩn `Alt+h/j/k/l`.
* [modules/kitty/files/kitty.conf](file:///home/loc/Workspaces/dotfiles/modules/kitty/files/kitty.conf): Phím tắt split, font size, clipboard.
* [modules/vscode/files/keybindings.json](file:///home/loc/Workspaces/dotfiles/modules/vscode/files/keybindings.json) & [modules/antigravity/files/keybindings.json](file:///home/loc/Workspaces/dotfiles/modules/antigravity/files/keybindings.json): Đồng bộ phím tắt giữa 2 IDE.
* `modules/kanata/files/kanata.kbd`: Cấu hình dual-role `CapsLock` và home-row navigation.

### 3.2. Bảng ma trận phím tắt hệ thống hoàn chỉnh

#### 1. Điều khiển Cửa sổ & Desktop (Umbriel + Noctalia)
* `Mod + Return`: Mở Kitty Terminal.
* `Mod + Space`: Mở Noctalia Application Launcher.
* `Mod + Q`: Đóng cửa sổ đang chọn.
* `Mod + F`: Bật/Tắt Fullscreen.
* `Mod + Shift + Space`: Bật/Tắt chế độ Floating cho cửa sổ.
* `Mod + h / j / k / l`: Di chuyển tiêu điểm (Focus) giữa các cửa sổ (Trái / Dưới / Trên / Phải).
* `Mod + Shift + h / j / k / l`: Đổi vị trí (Swap) cửa sổ.
* `Mod + 1 .. 9`: Chuyển sang Workspace tương ứng.
* `Mod + Shift + 1 .. 9`: Di chuyển cửa sổ đang chọn sang Workspace tương ứng.
* `Mod + N`: Mở bảng thông báo (Notification Center).
* `Mod + Shift + N`: Bật/Tắt Do Not Disturb (DND).
* `Mod + S`: Đóng băng màn hình và chụp ảnh chú thích (Screenshot Annotation).
* `Mod + R`: Bật/Tắt quay màn hình (Screen Recording toggle qua `noctalia/screen_recorder`).
* `Mod + V`: Mở lịch sử Clipboard (`clipse` trong cửa sổ Kitty nổi).
* `Mod + BackSpace`: Khóa màn hình (Lock screen).

#### 2. Điều hướng Terminal Multiplexer (Zellij / Kitty)
* `Alt + h / j / k / l`: Di chuyển giữa các pane (Vim navigation).
* `Alt + n`: Tạo pane mới chia đôi (Split).
* `Alt + Shift + n`: Tạo pane mới theo chiều dọc (Vertical split).
* `Alt + t`: Mở tab mới.
* `Alt + 1 .. 9`: Nhảy trực tiếp tới tab trong Zellij.
* `Alt + z`: Phóng to / thu nhỏ pane đang focus (Toggle fullscreen pane).
* `Alt + w`: Đóng pane hiện tại.

#### 3. Điều hướng IDE (VS Code & Antigravity IDE)
* `Ctrl + P`: Tìm và mở file nhanh (Quick open).
* `Ctrl + Shift + P`: Command Palette thực thi lệnh.
* `Ctrl + \``: Ẩn/Hiện Terminal tích hợp.
* `Ctrl + B`: Ẩn/Hiện Sidebar (File Explorer).
* `Ctrl + \`: Chia đôi editor (Split Editor).
* `Ctrl + Shift + F`: Tìm kiếm toàn bộ dự án (Global search).
* `Alt + Up / Down`: Di chuyển dòng code lên / xuống.
* `Ctrl + Shift + K`: Xóa dòng code hiện tại.

#### 4. Thao tác Chuột bằng Bàn phím (`warpd`)
* `Mod + X`: Kích hoạt chế độ Hint Mode (hiển thị lưới ký tự trên màn hình để nhảy con trỏ chuột tức thì).
* `f`: Chuột trái (Left click).
* `d`: Chuột giữa (Middle click).
* `s`: Chuột phải (Right click).

---

## 4. Kiểm thử nghiệm thu (Verification)
1. Thao tác `Mod+h/j/k/l` di chuyển mượt mà giữa các cửa sổ ứng dụng trên Wayland.
2. Thao tác `Alt+h/j/k/l` chỉ chuyển đổi giữa các pane bên trong terminal Zellij mà không bị compositor nuốt phím.
3. Nhấn nhả `CapsLock` hoạt động như `Escape` (thoát Insert mode trong Vim), nhấn giữ `CapsLock` hoạt động như `Ctrl` (dùng `Ctrl+C`, `Ctrl+V`).
4. Bộ gõ tiếng Việt Fcitx5 Bamboo không bị lỗi lặp ký tự hay xung đột phím tắt khi soạn thảo văn bản.
