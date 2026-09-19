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
           │ (Hold CapsLock + Key / Double-tap) │ (Press RightShift / Caps+Space)
┌─────────────────────────────────────────────────────────────────┐
│                        NORMAL LAYER (Default)                   │
│        Gõ phím mặc định 100% tự nhiên không delay/alteration    │
│        Double-tap CapsLock                   ──> NAVIGATE       │
│        Tap CapsLock + ` ──> NAVIGATE | 1 ──> NIRI | 2 ──> CHROM │
│        Tap CapsLock + Space                  ──> SUPER LAYER    │
│        Bấm RightShift (instant)              ──> SUPER LAYER    │
└─────────────────────────────────────────────────────────────────┘
           │ (Double-tap CapsLock / Caps+`)    │ (Press RightShift / Caps+Space)
           ▼                                   ▼
┌─────────────────────────┐         ┌─────────────────────────┐
│     NAVIGATE LAYER      │         │       SUPER LAYER       │
│  h/j/k/l -> Arrows      │         │  a -> One-shot Super    │
│  Tab     -> Alt + Tab   │         │  s -> One-shot Shift    │
│  Ctrl+h/l -> Prev/Next  │         │  d -> One-shot Ctrl     │
│  Ctrl+j/k -> PgDn/PgUp  │         │  f -> One-shot Alt      │
│  Ctrl+o/i -> Back/Fwd   │         │  Shift + a/s/d/f ->     │
│  w/e/b    -> Word jumps │         │    Sticky Lock Modifier │
│  x/y/p/z  -> Del/Cp/Pst │         │  c -> Lock Ctrl Mode    │
│  Bấm 1    ──> NIRI      │         │  RightShift ──> NORMAL  │
│  Bấm 2    ──> CHROMIUM  │         │  Esc / i ──> NORMAL     │
│  i / Esc  ──> NORMAL    │         │                         │
└─────────────────────────┘         └─────────────────────────┘
           │ Bấm 1 / Bấm 2                       │ Shift+a/s/d/f
           ▼                                     ▼
┌─────────────────────────┐         ┌─────────────────────────┐
│  NIRI / CHROMIUM LAYER  │         │   LOCKED MODIFIER MODES │
│  (Window / Browser Nav) │         │  (CTRL/SUPER/ALT/SHIFT) │
│  i / Esc ──> NORMAL     │         │  Mọi phím tự động kèm   │
│                         │         │  Modifier cho đến Esc   │
│                         │         │  Esc / Caps ──> NORMAL  │
└─────────────────────────┘         └─────────────────────────┘
```

### 3.1. Normal Layer (Lớp cơ bản)
- Gõ văn bản hoàn toàn nguyên bản như bàn phím phần cứng.
- **Chuyển tầng trực tiếp & an toàn:**
  - `CapsLock`: Double-tap nhanh để chuyển sang **Navigate Layer**. Không còn giữ CapsLock để vào navigate (tránh delay hoặc nhảy nhầm layer khi gõ nhanh). Nhấn thả đơn lẻ không thực hiện hành động nào (tránh mất caret/focus trong ô input).
  - `Hold / Tap CapsLock + <key>` (Hợp âm hoặc gõ tuần tự):
    - `CapsLock` + `Space` $\rightarrow$ Chuyển sang **Super Layer**.
    - `CapsLock` + `` ` `` $\rightarrow$ Chuyển sang **Navigate Layer**.
    - `CapsLock` + `1` $\rightarrow$ Chuyển sang **Niri Layer**.
    - `CapsLock` + `2` $\rightarrow$ Chuyển sang **Chromium Layer**.
  - `Shift + CapsLock`: Bật/tắt CapsLock phần cứng (khi thực sự cần gõ IN HOA toàn bộ).
  - `RightShift`: Nhấn trực tiếp = Chuyển ngay sang **Super Layer** (instant press toggle, zero latency, không cần giữ).

### 3.2. Navigate Layer (Lớp điều hướng & Chỉnh sửa)
- **Di chuyển con trỏ & Ứng dụng:**
  - `tab` $\rightarrow$ `Alt + Tab` (Chuyển nhanh qua lại giữa các cửa sổ ứng dụng).
  - `` ` `` $\rightarrow$ Duy trì **Navigate Layer**.
  - `h / j / k / l` $\rightarrow$ Mũi tên Trái / Xuống / Lên / Phải.
  - `Ctrl + h` $\rightarrow$ `Ctrl + Shift + Tab` (Tab trước).
  - `Ctrl + l` $\rightarrow$ `Ctrl + Tab` (Tab kế tiếp).
  - `Ctrl + j / k` $\rightarrow$ `Ctrl + PageDown / PageUp`.
  - `Ctrl + d / u` $\rightarrow$ `PageDown / PageUp`.
  - `Ctrl + o` $\rightarrow$ `Alt + Left` (Lịch sử trình duyệt lùi).
  - `Ctrl + i` $\rightarrow$ `Alt + Right` (Lịch sử trình duyệt tiến).
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
- **Chuyển tiếp & Thoát:**
  - `1` $\rightarrow$ Chuyển sang **Niri Layer**.
  - `2` $\rightarrow$ Chuyển sang **Chromium Layer**.
  - `i` $\rightarrow$ Trở về **Normal Layer** (theo thói quen Insert mode của Vim).
  - `Esc` hoặc `CapsLock` $\rightarrow$ Trở về **Normal Layer** (không kích hoạt in hoa).

### 3.3. Super Layer (Lớp phím bổ trợ One-Shot & Sticky)
- **One-Shot Modifiers (cho 1 thao tác tiếp theo, timeout 2000ms):**
  - `a` $\rightarrow$ `Super` (Windows key).
  - `s` $\rightarrow$ `Shift`.
  - `d` $\rightarrow$ `Ctrl`.
  - `f` $\rightarrow$ `Alt`.
  *(Kanata hỗ trợ dồn one-shot: Bấm `a` rồi `f` sẽ tự động thành `Super + Alt` cho phím gõ tiếp theo).*
- **Cơ chế thoát Super & Giữ phím chờ (Waiting Preserved):**
  - Trong `super`: Nhấn `RightShift`, `Esc`, `CapsLock`, hoặc `i` sẽ thoát về `normal` nhưng **không làm mất modifier đang chờ** (nhờ cơ chế `one-shot-pause-processing`). Người dùng có thể quay về `normal` và bấm phím mục tiêu để áp modifier đó.
  - Trong `normal`: Chỉ khi bấm `Esc` ở `normal`, Kanata mới **hủy toàn bộ modifier đang chờ** (cancel waiting).
- **Sticky Locking (cho thao tác lặp đi lặp lại):**
  - `Shift + a` $\rightarrow$ Khóa `Super` liên tục. Bấm `Esc` để chuyển thẳng vào chế độ gõ `super_locked` (mọi phím đều kèm Super).
  - `Shift + s` $\rightarrow$ Khóa `Shift` liên tục (`shift_locked`).
  - `Shift + d` hoặc `c` $\rightarrow$ Khóa `Ctrl` liên tục (`ctrl_locked`).
  - `Shift + f` $\rightarrow$ Khóa `Alt` liên tục (`alt_locked`).
  - **Điều hướng trong Locked Mode:** Giữ `CapsLock` 200ms để sang `Navigate` (`nav_slk`/`nav_clk`). Nhấn `i`/`Esc`/`Caps` trở lại Locked mode mà không làm mất trạng thái khóa modifier.
  - **Hủy chế độ khóa:** Chỉ khi nhấn `Esc` tại chế độ gõ (Normal / Locked Mode) mới giải phóng modifier và trở về `Normal` mặc định.

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
- **Thoát layer:**
  - `i`, `Esc`, hoặc `CapsLock` $\rightarrow$ Trở về **Normal Layer**.
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

### 3.5. Chromium Layer (Lớp thao tác trình duyệt)
- **Kích hoạt:** Trong `Navigate Layer` (hoặc `nav_slk`/`nav_clk`), bấm `2` (tương ứng tổ hợp `CapsLock + 2`).
- **Thao tác Tab:**
  - `t` $\rightarrow$ Mở tab mới (`Ctrl + T`).
  - `Shift + t` $\rightarrow$ Khôi phục tab vừa đóng (`Ctrl + Shift + T`).
  - `x` $\rightarrow$ Đóng tab hiện tại (`Ctrl + W`).
  - `m` $\rightarrow$ Toggle mute site / tab (`Alt + M` tương thích Vimium-C).
  - `h` $\rightarrow$ Tab trước (`Ctrl + Shift + Tab`).
  - `l` $\rightarrow$ Tab kế tiếp (`Ctrl + Tab`).
- **Cuộn trang:**
  - `j` $\rightarrow$ Cuộn xuống 1 trang (`PageDown`).
  - `k` $\rightarrow$ Cuộn lên 1 trang (`PageUp`).
- **Số & Nhảy tab:**
  - `1 - 9`, `0` $\rightarrow$ Gõ số bình thường (`1 - 9`, `0`).
  - `Ctrl + 1 - 9` $\rightarrow$ Nhảy trực tiếp tới tab 1..9 (`Ctrl + 1..9`).
  - `Ctrl + 0` $\rightarrow$ Nhảy tới tab cuối cùng (`Ctrl + 9`).
- **Thoát layer:**
  - `CapsLock`, `Esc`, hoặc `i` $\rightarrow$ Trở về **Normal Layer** (vẫn bảo toàn modifier waiting nếu có).

### 3.6. Hệ thống Chỉ báo trực quan (Mode Indicator & OSD Overlay)
- **On-Screen Display (OSD Overlay):** Khi người dùng chuyển sang bất kỳ chế độ nào (`NAVIGATE`, `CHROMIUM`, `NIRI`, `SUPER`, `CTRL_LOCKED`, v.v.), hệ thống lập tức hiển thị một popup badge nổi trên màn hình kèm tóm tắt phím tắt chính, tự động biến mất sau 1-2s và thay thế tức thì không dồn đọng thông báo.
- **Thanh trạng thái Niri (Noctalia Status Bar):** Widget `keymap` trên thanh bar hiển thị nhãn chế độ thời gian thực (`NORMAL`, `NAV`, `CHROM`, `NIRI`, `SUPER`, `C-LOCK`), cho phép click để mở bảng tra cứu phím tắt.
- **Cơ chế hoạt động:** Daemon `scripts/kanata-indicator.sh` lắng nghe sự kiện `Entered layer` từ Kanata stream, cập nhật trạng thái ra `/run/user/$UID/kanata-mode` và phát thông báo OSD qua `notify-send`. Chạy nền tự động qua systemd user service `kanata-indicator.service` và Niri autostart.

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
