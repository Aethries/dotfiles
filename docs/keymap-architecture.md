# System-Wide Vim-Style Modal Keymap Architecture

> **Trạng thái:** Chuẩn hóa kiến trúc (Issue #25)  
> **Phạm vi:** Toàn bộ hệ thống workstation (Kanata, Niri, Zellij, Neovim, Browser, Warpd)  
> **Ranh giới tham chiếu:** `docs/architecture.md` & `resources/nvim/lua/keymaps/manifest.lua`

---

## 1. Mục tiêu và Triết lý cốt lõi (Core Philosophy)

Hệ thống workstation tuân thủ triết lý **Keyboard-First & Modal Interaction**:
1. **Vim Everywhere:** Hành vi điều hướng cơ bản (`h/j/k/l`, nhảy từ, đầu/cuối dòng, cuộn trang) phải có ngữ nghĩa nhất quán trên toàn bộ hệ thống từ text editor, terminal multiplexer, trình duyệt web đến các hộp thoại GUI.
2. **Strict Layer Boundary (Phân tầng quyền hạn nghiêm ngặt):** Mỗi tầng phần mềm có một không gian điều khiển độc quyền, tuyệt đối không giẫm chân lên nhau.
3. **Ergonomic Home-Row Focus:** Hạn chế tối đa việc nhấc tay khỏi hàng phím chính (Home Row) để với chuột, phím điều hướng (Arrows) hay các phím chức năng xa (Esc, Function keys).
4. **Zero Lockout & Hardware Fallback:** Luôn tồn tại cơ chế thoát hiểm cấp phần cứng (Escape Hatches) để trả lại trạng thái bàn phím nguyên bản (phục vụ chơi game, máy ảo, remote desktop, nhập tiếng Việt tốc độ cao).

---

## 2. Ma trận phân quyền kiểm soát phím (Ownership Matrix)

Bảng phân cấp xác định rõ phần mềm nào chịu trách nhiệm cho từng không gian phím:

| Tầng (Layer) | Công nghệ / Phần mềm | Tiền tố / Phím kích hoạt | Phạm vi trách nhiệm |
| :--- | :--- | :--- | :--- |
| **0. Kernel / evdev** | **Kanata** | Home-row hold, `Space` hold, `Caps` | Phân giải tap/hold, sinh lớp điều hướng toàn cục (Nav layer), mod-tap, emergency bypass. |
| **1. Compositor** | **Niri** (Wayland) | `Super` (`Mod`), `Super+Shift`, `Super+Ctrl` | Quản lý cửa sổ (split, scroll column), chuyển workspace, mở app, lock screen. |
| **2. Multiplexer** | **Zellij** | `Ctrl+Shift+<key>`, `Ctrl+h/j/k/l` | Quản lý pane/tab terminal; định tuyến điều hướng giữa các split nội bộ và Neovim. |
| **3. Editor** | **Neovim** / **Antigravity** | `<leader>` (`Space` trong normal mode), `<C-w>` | Chỉnh sửa văn bản, điều hướng AST code, thao tác file, gọi LSP & Git. |
| **4. Browser & GUI** | **Chrome + Vimium-C** / **Warpd** | `f`, `F`, `j/k`, `d/u`, `Super+Alt+P` | Bấm link, điều hướng DOM web, mô phỏng con trỏ chuột không dùng chuột vật lý. |

---

## 3. Hệ thống Layer toàn cục của Kanata (Global Layer Hierarchy)

```
┌─────────────────────────────────────────────────────────────────┐
│                        HARDWARE BYPASS                          │
│        (Kích hoạt bằng LShift + RShift: Bỏ qua toàn bộ)         │
└─────────────────────────────────────────────────────────────────┘
                               ▲
                               │ Toggle Bypass
┌─────────────────────────────────────────────────────────────────┐
│                        BASE LAYER (QWERTY)                      │
│        Home-Row Mods: A(Meta) S(Alt) D(Ctrl) F(Shift)           │
│                       J(Shift) K(Ctrl) L(Alt) ;(Meta)           │
│        Space -> Tap: Space | Hold: NAV LAYER                    │
│        CapsLock -> Tap: Esc | Hold: Ctrl (hoặc Mouse Layer)     │
└─────────────────────────────────────────────────────────────────┘
           │ (Hold Space)                     │ (Hold CapsLock / Chord)
┌─────────────────────────────────────────────────────────────────┐
│                        NORMAL LAYER (Default)                   │
│        Gõ phím mặc định 100% tự nhiên không delay/alteration    │
│        Giữ CapsLock (200ms)    ──> NAVIGATE LAYER               │
│        Giữ RightShift (200ms)  ──> SUPER LAYER                  │
└─────────────────────────────────────────────────────────────────┘
           │ (Hold CapsLock 200ms)             │ (Hold RightShift 200ms)
           ▼                                   ▼
┌─────────────────────────┐         ┌─────────────────────────┐
│     NAVIGATE LAYER      │         │       SUPER LAYER       │
│  h/j/k/l -> Arrows      │         │  a -> One-shot Super    │
│  Ctrl+h/l -> Prev/Next  │         │  s -> One-shot Alt      │
│  Ctrl+j/k -> PgDn/PgUp  │         │  d -> One-shot Ctrl     │
│  Ctrl+o/i -> Back/Fwd   │         │  f -> One-shot Shift    │
│  w/e/b    -> Word jumps │         │  c -> Lock Ctrl Mode    │
│  x/y/p/z  -> Del/Cp/Pst │         │                         │
│  Bấm 1    ──> NIRI      │         │  Esc -> Về Normal       │
│  Esc      ──> NORMAL    │         └─────────────────────────┘
└─────────────────────────┘                      │ Bấm c
           │ Bấm 1                               ▼
           ▼                        ┌─────────────────────────┐
┌─────────────────────────┐         │    CTRL_LOCKED LAYER    │
│       NIRI LAYER        │         │  Mọi phím tự động kèm   │
│  h/l     -> Focus Col   │         │  Ctrl+<key>             │
│  j/k     -> Focus Ws    │         │                         │
│  1-9     -> Jump Ws     │         │  Esc -> Về Normal       │
│  Ctrl+...-> Move Col/Ws │         └─────────────────────────┘
│  c/p/s/r/d/t -> Actions │
│  Esc     ──> NORMAL     │
└─────────────────────────┘
```

### 3.1. Normal Layer (Lớp cơ bản)
- Gõ văn bản hoàn toàn nguyên bản như bàn phím phần cứng.
- **Chuyển tầng thông minh (Latching layer switch):**
  - `CapsLock`: Nhấn thả nhanh (< 200ms) = phím `Esc`. Giữ $\ge$ 200ms = Chuyển hẳn sang **Navigate Layer** (thả tay ra vẫn ở Navigate).
  - `RightShift`: Nhấn thả nhanh (< 200ms) = phím `RightShift`. Giữ $\ge$ 200ms = Chuyển hẳn sang **Super Layer** (thả tay ra vẫn ở Super).

### 3.2. Navigate Layer (Lớp điều hướng & Chỉnh sửa)
- **Di chuyển con trỏ:**
  - `h / j / k / l` $\rightarrow$ Mũi tên Trái / Xuống / Lên / Phải.
  - `Ctrl + h` $\rightarrow$ `Ctrl + Shift + Tab` (Tab trước).
  - `Ctrl + l` $\rightarrow$ `Ctrl + Tab` (Tab kế tiếp).
  - `Ctrl + j / k` $\rightarrow$ `Ctrl + PageDown / PageUp`.
  - `Ctrl + d / u` $\rightarrow$ `PageDown / PageUp`.
  - `Ctrl + o / i` $\rightarrow$ `Alt + Left / Right` (Lịch sử trình duyệt / Jump list).
- **Nhảy từ & Biên dòng:**
  - `w` $\rightarrow$ `Ctrl + Right` (Nhảy tới đầu từ kế).
  - `e` / `b` $\rightarrow$ `Ctrl + Left` (Nhảy về đầu từ trước).
  - `0` $\rightarrow$ `Home` (Đầu dòng).
  - `$` (`Shift + 4`) $\rightarrow$ `End` (Cuối dòng).
- **Thao tác chỉnh sửa nhanh:**
  - `x` $\rightarrow$ `Delete` (Xóa ký tự).
  - `y` $\rightarrow$ `Ctrl + C` (Sao chép).
  - `p` $\rightarrow$ `Ctrl + V` (Dán).
  - `z` $\rightarrow$ `Ctrl + Z` (Hoàn tác / Undo).
  - `r` $\rightarrow$ `Ctrl + Y` (Làm lại / Redo).
  - `/` $\rightarrow$ `Ctrl + F` (Tìm kiếm).
- **Chuyển tiếp:**
  - `1` $\rightarrow$ Chuyển sang **Niri Layer**.
  - `Esc` $\rightarrow$ Trở về **Normal Layer**.

### 3.3. Super Layer (Lớp phím bổ trợ One-Shot & Sticky)
- **One-Shot Modifiers (chờ 1000ms):**
  - `a` $\rightarrow$ `Super` (Windows key).
  - `s` $\rightarrow$ `Alt`.
  - `d` $\rightarrow$ `Ctrl`.
  - `f` $\rightarrow$ `Shift`.
  *(Kanata hỗ trợ dồn one-shot: Bấm `a` rồi `f` sẽ tự động thành `Super + Shift` cho phím gõ tiếp theo).*
- **Chế độ khóa Ctrl (Ctrl Locked Mode):**
  - `c` $\rightarrow$ Chuyển sang layer `ctrl_locked`. Ở chế độ này, mọi ký tự gõ vào đều tự động kèm Ctrl (`Ctrl+C`, `Ctrl+V`, `Ctrl+A`, v.v.), chỉ hủy và trở về `normal` khi bấm `Esc`.
- **Thoát:** `Esc` giải phóng mọi modifier và trở về **Normal Layer**.

### 3.4. Niri Layer (Lớp điều khiển Window Manager Niri)
- **Điều hướng cửa sổ & Workspace:**
  - `h / l` $\rightarrow$ Chuyển focus cột trái / phải (`Mod+H` / `Mod+L`).
  - `j / k` $\rightarrow$ Chuyển workspace lên / xuống (`Mod+J` / `Mod+K`).
  - `1 - 9` $\rightarrow$ Nhảy trực tiếp tới workspace 1..9 (`Mod+1..9`).
- **Đổi vị trí cửa sổ (Reposition):**
  - `Ctrl + h / l` $\rightarrow$ Di chuyển cột window sang trái / phải (`Mod+Ctrl+H` / `Mod+Ctrl+L`).
  - `Ctrl + j / k` $\rightarrow$ Di chuyển window sang workspace dưới / trên (`Mod+Ctrl+J` / `Mod+Ctrl+K`).
  - `Ctrl + 1 - 9` $\rightarrow$ Chuyển window đang focus sang workspace tương ứng (`Mod+Ctrl+1..9`).
  - `Shift + h / l` $\rightarrow$ Chuyển focus sang màn hình trái / phải.
  - `Alt + h / l` $\rightarrow$ Chuyển window sang màn hình trái / phải.
- **Hành động One-shot (Chạy xong tự động về Normal):**
  - `c` $\rightarrow$ Căn giữa cột (`Mod+C`).
  - `p` $\rightarrow$ Mở Project launcher (`Mod+P`).
  - `s` $\rightarrow$ Chụp ảnh màn hình (`Mod+S`).
  - `r` $\rightarrow$ Quay màn hình (`Mod+R`).
  - `d` $\rightarrow$ Mở Menu ứng dụng (`Mod+D`).
  - `t` / `Enter` $\rightarrow$ Mở Terminal (`Mod+T` / `Mod+Return`).
  - `o` $\rightarrow$ Toggle Overview (`Mod+O`).
  - `v` $\rightarrow$ Mở Clipboard (`Mod+V`).
- **Hành động duy trì:**
  - `f` $\rightarrow$ Fullscreen (`Mod+F`).
  - `q` $\rightarrow$ Đóng cửa sổ (`Mod+Q`).
  - `Esc` $\rightarrow$ Trở về **Normal Layer**.

---

## 4. Bảng phân định & Xử lý xung đột (Conflict Resolution Table)

Để bảo đảm không có phím tắt bị xung đột hoặc trùng lặp không rõ mục đích:

| Modifier / Tổ hợp | Người sở hữu duy nhất | Mục đích sử dụng | Tránh xung đột với |
| :--- | :--- | :--- | :--- |
| `Super + <key>` | **Niri** | Quản lý màn hình, chia cột, launch app | Cấm Kanata hoặc Neovim dùng `Super` làm modifier chính |
| `Ctrl + Shift + <key>` | **Zellij** | Quản lý tab, tạo pane split, search session | Ứng dụng GUI không được dùng tổ hợp này làm default |
| `Ctrl + h/j/k/l` | **Zellij $\leftrightarrow$ Neovim** | Điều hướng liền mạch giữa editor splits và terminal panes qua plugin navigator | Kanata Nav layer không gán đè `Ctrl+h/j/k/l` |
| `<leader>` (`Space`) | **Neovim** (Normal Mode) | Thao tác lệnh editor (`<leader>ff`, `<leader>w`, v.v.) | Kanata chỉ giữ `Space` trong typing mode; khi thả ra trong Neovim Normal mode thì Neovim nhận `<leader>` bình thường |
| `Alt + <key>` | **App Local / GUI** | Menu, shortcut nội bộ phần mềm | Tránh gán đè ở cấp WM |

---

## 5. Hợp đồng tích hợp với Neovim Manifest & Lộ trình tự động hóa (#30)

1. **Neovim Manifest làm Single Source of Truth:**
   - File `resources/nvim/lua/keymaps/manifest.lua` lưu trữ toàn bộ định nghĩa keymaps của editor và global actions.
   - Script `scripts/generate-keymaps.lua` hiện tại tự động sinh keybindings cho Antigravity IDE (`keybindings.generated.jsonc`) và tài liệu Markdown.
2. **Mở rộng cho Kanata (Feature 09, Issue #30):**
   - Khi cấu hình Kanata (`.kbd`) hoàn thiện, bảng ánh xạ các layer phím sẽ được chuẩn hóa thành cấu trúc dữ liệu declaratively.
   - Tránh việc cấu hình thủ công ở nhiều nơi gây phân mảnh và drift phím tắt.

---

## 6. Tiêu chí kiểm định chất lượng (QA Verification Checklist)

- [x] Tài liệu kiến trúc phân tầng rõ ràng giữa 5 cấp độ phần mềm.
- [x] Không có xung đột giữa `Super` (Niri), `Ctrl+Shift` (Zellij) và `Space/Caps` (Kanata).
- [x] Cơ chế Hard Bypass (Dual Shift toggle) được định nghĩa chi tiết để ngăn chặn lockout.
- [x] Quy chuẩn tương thích với bộ gõ tiếng Việt Fcitx5 (thời gian debounce và release).
