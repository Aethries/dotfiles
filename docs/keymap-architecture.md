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
           │ (Hold CapsLock + Key / Tap CapsLock) │ (Press RightShift / Double-tap Caps)
┌────────────────────────────────────────────────────────────────────────┐
│                         NORMAL LAYER (Default)                         │
│        Gõ phím mặc định 100% tự nhiên không delay/alteration           │
│        Single-tap CapsLock                   ──> NAVIGATE              │
│        Double-tap CapsLock                   ──> SUPER LAYER           │
│        Tap/Hold CapsLock + ` ──> NAV | 1 ──> NIRI | 2 ──> CHROM        │
│        Tap/Hold CapsLock + 3 ──> TERM | 4 ──> WARPD | Spc ──> SUPER   │
│        Bấm RightShift (instant)              ──> SUPER LAYER           │
└────────────────────────────────────────────────────────────────────────┘
           │ (Single-tap CapsLock / Caps+`)    │ (Double-tap Caps / RightShift)
           ▼                                   ▼
┌─────────────────────────┐         ┌─────────────────────────┐
│     NAVIGATE LAYER      │         │       SUPER LAYER       │
│  h/j/k/l -> Arrows      │         │  a -> One-shot Super    │
│  gg / G  -> Top / End   │         │  s -> One-shot Shift    │
│  w / e   -> Next word   │         │  d -> One-shot Ctrl     │
│  b       -> Prev word   │         │  f -> One-shot Alt      │
│  Tab     -> Alt + Tab   │         │  Shift + a/s/d/f ->     │
│  Ctrl+h/l -> Prev/Next  │         │    Sticky Lock Modifier │
│  Ctrl+j/k -> PgDn/PgUp  │         │  c -> Lock Ctrl Mode    │
│  v ──> VISUAL (Select)  │         │  RightShift ──> NORMAL  │
│  m / M ──> WARPD (Mouse)│         │  Esc / i ──> NORMAL     │
│  x/y/p/z  -> Del/Cp/Pst │         │                         │
│  1:Niri | 2:Chrom | 3:Tm│         │                         │
│  Double Caps / Esc ──> N│         │                         │
└─────────────────────────┘         └─────────────────────────┘
           │ Bấm 1 / 2 / 3                       │ Shift+a/s/d/f
           ▼                                     ▼
┌─────────────────────────────────┐ ┌─────────────────────────┐
│ NIRI / CHROMIUM / TERMINALS     │ │   LOCKED MODIFIER MODES │
│ 1: Niri (WM, Workspaces)        │ │  (CTRL/SUPER/ALT/SHIFT) │
│ 2: Chromium (Tabs, Vimium-C)    │ │  Mọi phím tự động kèm   │
│ 3: Terminals (Zellij Multiplex) │ │  Modifier cho đến Esc   │
│ Chuyển qua lại: Hold Caps+1/2/3 │ │  Esc / Caps ──> NORMAL  │
│ Thoát: Double Caps / Esc ──> N  │ └─────────────────────────┘
└─────────────────────────────────┘
```

### 3.1. Normal Layer (Lớp cơ bản)
- Gõ văn bản hoàn toàn nguyên bản như bàn phím phần cứng.
- **Chuyển tầng trực tiếp & an toàn:**
  - `CapsLock`: 
    - **Single-tap**: Chuyển ngay sang **Navigate Layer** (Vim motions).
    - **Double-tap**: Chuyển sang **Super Layer** (One-shot / Sticky Modifiers).
    - **Giữ (Hold)**: Đóng vai trò phím bổ trợ hợp âm (`caps_mode`) để chuyển nhanh sang các layer chuyên biệt mà không tạo bất kỳ delay nào khi thả ra.
  - `Hold / Tap CapsLock + <key>` (Hợp âm hoặc gõ tuần tự):
    - `CapsLock` + `Space` $\rightarrow$ Chuyển sang **Super Layer**.
    - `CapsLock` + `` ` `` $\rightarrow$ Chuyển sang **Navigate Layer**.
    - `CapsLock` + `1` $\rightarrow$ Chuyển sang **Niri Layer**.
    - `CapsLock` + `2` $\rightarrow$ Chuyển sang **Chromium Layer**.
    - `CapsLock` + `3` $\rightarrow$ Chuyển sang **Terminals Layer**.
    - `CapsLock` + `4` $\rightarrow$ Kích hoạt **Warpd Hint Mode** (Điều khiển chuột bằng bàn phím).
  - `Shift + CapsLock`: Bật/tắt CapsLock phần cứng an toàn (khi thực sự cần gõ IN HOA toàn bộ, không lo bị bấm nhầm).
  - `RightShift`: Nhấn trực tiếp = Chuyển ngay sang **Super Layer** (instant press toggle, zero latency, không cần giữ).
- **Cơ chế thoát hiểm Esc toàn cục tức thì (Zero-Latency Instant Esc Reset):**
  - Áp dụng trên toàn bộ 100% các layer của hệ thống (`Normal`, `Navigate`, `Visual`, `Super`, `Chromium`, `Terminals`, `Niri`, `Ctrl/Super/Alt/Shift Locked`, `Bypass`).
  - **Single-tap `Esc` (Instant 0ms latency)**: Giải phóng tức thì toàn bộ modifier đang giữ/chờ (`Meta`, `Ctrl`, `Alt`, `Shift`), gửi tín hiệu `Esc` sạch và đưa bàn phím về trạng thái gõ chữ thông thường (`Normal Layer`).
  - Đã loại bỏ hoàn toàn tap-dance 250ms trên `Esc`, triệt tiêu độ trễ khi thoát Vim hoặc đóng cửa sổ popup.

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
- **Nhảy từ, Biên dòng & Tài liệu:**
  - `w` hoặc `e` $\rightarrow$ `Ctrl + Right` (Nhảy tới đầu từ tiếp theo).
  - `b` $\rightarrow$ `Ctrl + Left` (Nhảy về đầu từ trước đó).
  - `gg` (Double-tap `g`) $\rightarrow$ `Ctrl + Home` (Lên đầu trang / file).
  - `G` (`Shift + g`) $\rightarrow$ `Ctrl + End` (Xuống cuối trang / file).
  - `0` $\rightarrow$ `Home` (Đầu dòng).
  - `$` (`Shift + 4`) $\rightarrow$ `End` (Cuối dòng).
- **Thao tác chọn văn bản (Selection) & Visual Mode:**
  - **Cách 1 - Chọn trực tiếp trong Navigate (Giữ Shift):**
    - `Shift + w / e` $\rightarrow$ `Ctrl + Shift + Right` (Bôi đen từ tiếp theo).
    - `Shift + b` $\rightarrow$ `Ctrl + Shift + Left` (Bôi đen từ trước đó).
    - `Shift + h / j / k / l` $\rightarrow$ `Shift + Arrows` (Bôi đen theo ký tự / dòng).
  - **Cách 2 - Vim Visual Mode (Bấm `v` trong Navigate - Không cần giữ phím):**
    - Nhấn `v` $\rightarrow$ Vào **Visual Layer** (Badge `VIS` trên thanh trạng thái Noctalia).
    - `w / e` $\rightarrow$ Bôi đen liên tục từng từ về trước (`Ctrl + Shift + Right`).
    - `b` $\rightarrow$ Bôi đen liên tục từng từ lùi lại (`Ctrl + Shift + Left`).
    - `h / j / k / l` $\rightarrow$ Bôi đen ký tự / dòng (`Shift + Arrows`).
    - `0` $\rightarrow$ Bôi đen về đầu dòng (`Shift + Home`).
    - `$` (`Shift + 4`) $\rightarrow$ Bôi đen về cuối dòng (`Shift + End`).
    - `gg` / `G` $\rightarrow$ Bôi đen lên đầu trang / xuống cuối trang.
    - **Thao tác kết thúc:**
      - `y` $\rightarrow$ Copy (`Ctrl + C`) và tự động quay về `Navigate Layer`.
      - `x` $\rightarrow$ Cut (`Ctrl + X`) và tự động quay về `Navigate Layer`.
      - `c` $\rightarrow$ Cut (`Ctrl + X`) và chuyển thẳng về `Normal Layer` để gõ chữ thay thế (chuẩn thao tác `c` của Vim).
      - `p` $\rightarrow$ Dán đè (`Ctrl + V`) và quay về `Navigate Layer`.
      - `v` hoặc `Esc` $\rightarrow$ Hủy chọn (`v` về Navigate, `Esc` về Normal).
- **Thao tác chỉnh sửa nhanh:**
  - `x` $\rightarrow$ `Delete` (Xóa ký tự).
  - `y` $\rightarrow$ `Ctrl + C` (Sao chép).
  - `p` $\rightarrow$ `Ctrl + V` (Dán).
  - `z` $\rightarrow$ `Ctrl + Z` (Hoàn tác / Undo).
  - `r` $\rightarrow$ `Ctrl + Y` (Làm lại / Redo).
  - `/` $\rightarrow$ `Ctrl + F` (Tìm kiếm).
- **Chuyển tiếp & Thoát thông minh:**
  - `1` $\rightarrow$ Chuyển sang **Niri Layer**.
  - `2` $\rightarrow$ Chuyển sang **Chromium Layer**.
  - `3` $\rightarrow$ Chuyển sang **Terminals Layer**.
  - `m` $\rightarrow$ Kích hoạt **Warpd Hint Mode** (Nhảy & click nhanh bằng bàn phím).
  - `M` (`Shift + m`) $\rightarrow$ Kích hoạt **Warpd Normal Movement** (Rê chuột bằng vi-keys `h/j/k/l`).
  - `Hold CapsLock + 1/2/3/4/`` $\rightarrow$ Chuyển trực tiếp sang các layer tương ứng mà không bị thoát về Normal.
  - `Single-tap CapsLock` $\rightarrow$ Duy trì ở **Navigate Layer**.
  - `Double-tap CapsLock`, `Esc`, hoặc `i` $\rightarrow$ Trở về **Normal Layer**.

### 3.3. Super Layer (Lớp phím bổ trợ One-Shot, Chords & Sticky)
- **One-Shot Modifiers & Chords trên hàng `a s d f` (timeout chập 150ms, timeout giữ 2000ms):**
  - **Phím đơn lẻ:**
    - `a` $\rightarrow$ `Super` (Windows key).
    - `s` $\rightarrow$ `Shift`.
    - `d` $\rightarrow$ `Ctrl`.
    - `f` $\rightarrow$ `Alt`.
  - **Chập 2 phím đồng thời (Dual Chords):**
    - `a + d` $\rightarrow$ `Super + Ctrl`
    - `a + s` $\rightarrow$ `Super + Shift`
    - `a + f` $\rightarrow$ `Super + Alt`
    - `s + d` / `d + s` $\rightarrow$ `Ctrl + Shift`
    - `d + f` $\rightarrow$ `Ctrl + Alt`
    - `s + f` $\rightarrow$ `Shift + Alt`
  - **Chập 3 phím đồng thời (Triple Chords):**
    - `a + d + f` $\rightarrow$ `Super + Ctrl + Alt`
    - `a + s + f` $\rightarrow$ `Super + Shift + Alt`
    - `a + s + d` $\rightarrow$ `Super + Shift + Ctrl`
    - `s + d + f` $\rightarrow$ `Ctrl + Shift + Alt` (Meh key)
  - **Chập 4 phím đồng thời (Quad Chord):**
    - `a + s + d + f` $\rightarrow$ `Super + Ctrl + Shift + Alt` (Hyper key)
  *(Có thể gõ chập đồng thời hoặc gõ dồn tuần tự; khi gõ phím mục tiêu Kanata sẽ áp đúng tổ hợp và tự động giải phóng).*
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
- **Thoát layer:**
  - `Single-tap CapsLock` $\rightarrow$ Trở về **Navigate Layer** (chế độ điều hướng mặc định).
  - `Double-tap CapsLock`, `Esc`, hoặc `i` $\rightarrow$ Trở về **Normal Layer**.
  - `Hold CapsLock + 1/2/3/`` $\rightarrow$ Chuyển trực tiếp giữa các layer.

### 3.5. Chromium Layer (Lớp thao tác trình duyệt)
- **Kích hoạt:** Trong `Navigate Layer` (hoặc `nav_slk`/`nav_clk`), bấm `2` (tương ứng tổ hợp `CapsLock + 2`).
- **Thao tác Tab:**
  - `t` $\rightarrow$ Mở tab mới (`Ctrl + T`).
  - `Shift + t` $\rightarrow$ Khôi phục tab vừa đóng (`Ctrl + Shift + T`).
  - `r` $\rightarrow$ Tải lại trang (`Ctrl + R`). `Shift + r` $\rightarrow$ Tải lại không cache (`Ctrl + Shift + R`).
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
  - `Single-tap CapsLock` $\rightarrow$ Trở về **Navigate Layer** (chế độ điều hướng mặc định).
  - `Double-tap CapsLock`, `Esc`, hoặc `i` $\rightarrow$ Trở về **Normal Layer**.
  - `Hold CapsLock + 1/3/`` $\rightarrow$ Chuyển trực tiếp sang Niri, Terminals, Navigate.

### 3.6. Terminals Layer (Lớp thao tác Terminal Multiplexer Zellij)
- **Kích hoạt:**
  - Trong `Normal Layer`: Bấm tổ hợp hoặc gõ tuần tự `CapsLock + 3`.
  - Trong `Navigate Layer` (hoặc `nav_slk`/`nav_clk`): Bấm phím `3`.
  - Giữ `CapsLock` và bấm `3` từ bất kỳ layer nào.
- **Điều hướng Panes & CLI:**
  - `h` $\rightarrow$ Chuyển focus pane sang trái (`Ctrl + H`, tương thích Neovim split).
  - `l` $\rightarrow$ Chuyển focus pane sang phải (`Ctrl + L`, tương thích Neovim split).
  - `j` $\rightarrow$ Mũi tên xuống (`Down`) để cuộn lịch sử lệnh CLI / chọn menu fzf / TUI. (Khi kèm Ctrl: `Ctrl + J` để chuyển pane xuống trong Zellij).
  - `k` $\rightarrow$ Mũi tên lên (`Up`) để cuộn lịch sử lệnh CLI / chọn menu fzf / TUI. (Khi kèm Ctrl: `Ctrl + K` để chuyển pane lên trong Zellij).
- **Quản lý Session, Window & Pane:**
  - `s` $\rightarrow$ Mở Zellij Session Manager (`Ctrl + Shift + S`).
  - `x` $\rightarrow$ Đóng pane đang focus (`Ctrl + Shift + W`). `Shift + x` $\rightarrow$ Đóng cả tab (`Ctrl + Shift + Q`).
  - `w` $\rightarrow$ Toggle Floating Panes (`Ctrl + Shift + P`). `Shift + w` $\rightarrow$ Embed/Float pane (`Ctrl + Shift + E`).
  - `t` $\rightarrow$ Tạo tab mới trong Zellij (`Ctrl + Shift + T`).
  - `q` $\rightarrow$ Đóng tab hiện tại (`Ctrl + Shift + Q`).
  - `n` $\rightarrow$ Tạo pane split mới bên phải (`Ctrl + Shift + N`).
  - `d` $\rightarrow$ Tạo pane split mới bên dưới (`Ctrl + Shift + D`).
  - `f` $\rightarrow$ Phóng to / Thu nhỏ pane đang chọn (`Ctrl + Shift + F` - Fullscreen).
  - `r` $\rightarrow$ Đổi tên tab (`Ctrl + Shift + R`).
- **Scroll & Tìm kiếm:**
  - `b` $\rightarrow$ Chế độ xem lại & cuộn trang (`Ctrl + Shift + B` - Scroll mode).
  - `/` $\rightarrow$ Tìm kiếm log scrollback (`Ctrl + Shift + /`).
- **Tiện ích & Plugins Zellij:**
  - `a` $\rightarrow$ Mở Room plugin tìm nhanh tab/session (`Ctrl + Shift + A`).
  - `z` $\rightarrow$ Mở bảng trợ giúp phím tắt Zellij (`Ctrl + Shift + Z` - Zellij forgot).
  - `[` / `]` $\rightarrow$ Chuyển tab trước / tab kế (`Ctrl + Shift + [` / `Ctrl + Shift + ]`).
  - `1 - 9`, `0` $\rightarrow$ Gõ số bình thường; `Ctrl + 1 - 9`: Nhảy trực tiếp tới tab 1..9 (`Ctrl + Shift + 1..9`).
- **Thoát layer:**
  - `Single-tap CapsLock` $\rightarrow$ Trở về **Navigate Layer** (chế độ điều hướng mặc định).
  - `Double-tap CapsLock`, `Esc`, hoặc `i` $\rightarrow$ Trở về **Normal Layer**.
  - `Hold CapsLock + 1/2/`` $\rightarrow$ Chuyển trực tiếp sang Niri, Chromium, Navigate.

### 3.7. Warpd Pointer Layer (Điều khiển chuột toàn diện bằng bàn phím - Issue #28)
- **Kích hoạt tức thì & Đồng bộ phím tắt:**
  - Trong **Navigate Layer**:
    - Nhấn `m` vào **Hint Mode**; Nhấn `M` (`Shift + m`) vào **Normal Movement Mode** (tự động chuyển Kanata về `normal` ngay lập tức để khi thoát Warpd là gõ phím được ngay).
    - `Single-tap CapsLock`: Trở về thẳng **Normal Layer** chỉ với 1 chạm (không cần bấm 2 lần).
  - Hợp âm toàn cục (`Normal Layer`):
    - `Hold CapsLock + m` hoặc gõ chuỗi `CapsLock m` $\rightarrow$ Kích hoạt **Hint Mode**.
    - `Hold CapsLock + Shift + m` $\rightarrow$ Kích hoạt **Normal Movement Mode**.
    - `Hold / Tap CapsLock + 4` $\rightarrow$ Kích hoạt **Hint Mode** (chuỗi số 1..4).
  - Phím tắt Compositor Niri trực tiếp: `Mod + Alt + P` (Hint), `Mod + Alt + M` (Normal), `Mod + Alt + G` (Grid), `Mod + Alt + Escape` (Thoát/Kill Warpd). Hỗ trợ cả khi đang giữ Shift (`Mod + Alt + Shift + P/M`).
- **Thao tác trong Hint Mode (Vimium-style Screen Target Selection):**
  - Màn hình hiển thị lưới nhãn 2 ký tự nhỏ gọn (`hint_size: 13`), nền bán trong suốt (`#1e1e2ecc`) không che khuất chữ bên dưới.
  - Gõ 2 ký tự: Con trỏ lập tức nhảy đến vị trí đó và click chuột trái, sau đó tự động thoát mode.
  - `Esc`: Hủy và thoát hint mode.
  - `Backspace`: Xóa ký tự đầu tiên nếu gõ nhầm.
- **Thao tác trong Normal Movement Mode (Di chuyển chuột bằng Vi-keys):**
  - **Điều hướng cơ bản & Gia tốc:**
    - `h / j / k / l` $\rightarrow$ Rê chuột Trái / Xuống / Lên / Phải (phản hồi 10ms, tốc độ khởi điểm 700px/s).
    - `a` (giữ) $\rightarrow$ Bứt tốc tối đa lên 4500px/s (gia tốc 9000px/s², lướt toàn màn hình trong 0.4s).
    - `s` (giữ) $\rightarrow$ Giảm tốc độ xuống 40px/s (Decelerator - chậm lại để căn chỉnh chính xác từng pixel).
  - **Nhảy biên & Nhảy tâm tức thì:**
    - `H` (`Shift + h`) $\rightarrow$ Nhảy lên mép trên cùng màn hình (Top edge).
    - `L` (`Shift + l`) $\rightarrow$ Nhảy xuống mép dưới cùng màn hình (Bottom edge).
    - `0` $\rightarrow$ Nhảy sang mép trái cùng màn hình (Leftmost edge).
    - `$` (`Shift + 4`) $\rightarrow$ Nhảy sang mép phải cùng màn hình (Rightmost edge).
    - `M` (`Shift + m`) $\rightarrow$ Nhảy thẳng vào chính giữa màn hình (Center / Middle cả ngang lẫn dọc).
  - **Nhảy mục tiêu trực tiếp trong phiên di chuyển (In-session Jump):**
    - `f` $\rightarrow$ Kích hoạt ngay Hint Mode trong khi đang di chuyển mà không cần thoát mode!
    - `g` $\rightarrow$ Kích hoạt ngay Grid Mode (lưới 2x2 `u i j k`).
  - **Click chuột, Kéo thả & Bôi đen văn bản:**
    - `Space` $\rightarrow$ Click chuột trái và duy trì mode (Persistent Click - dùng để click nhiều lần hoặc double-click).
    - `i` $\rightarrow$ Click chuột trái tức thì và thoát mode ngay về chế độ gõ văn bản (Oneshot Click - theo quy ước phím `i` Insert của Vim).
    - `.` $\rightarrow$ Click chuột phải.
    - `,` $\rightarrow$ Click chuột giữa.
    - `v` $\rightarrow$ Bật/tắt chế độ kéo thả (Drag / Visual mode) để bôi đen văn bản. Khi bật `v`, có thể bấm tiếp `h/j/k/l` hoặc bấm `f` để nhảy thẳng đến điểm cuối vùng chọn!
    - `c` $\rightarrow$ Copy vùng chọn và thoát mode (`copy_and_exit`).
  - **Cuộn trang:**
    - `d / u` $\rightarrow$ Cuộn trang Xuống / Lên mượt mà (tương ứng Ctrl+d / Ctrl+u của Vim).
  - **Thoát mode & Chuyển đổi:**
    - `Esc` $\rightarrow$ Thoát chế độ điều khiển chuột về gõ văn bản bình thường.
    - `Mod + Alt + Escape` $\rightarrow$ Đóng cưỡng bức Warpd từ Niri compositor nếu bị vướng input grab.

### 3.8. Hệ thống Chỉ báo trực quan (Mode Indicator & OSD Overlay)
- **On-Screen Display (OSD Overlay):** Khi người dùng chuyển sang bất kỳ chế độ nào (`NAVIGATE`, `CHROMIUM`, `TERMINALS`, `NIRI`, `SUPER`, `CTRL_LOCKED`, v.v.), hệ thống lập tức hiển thị một popup badge nổi trên màn hình kèm tóm tắt phím tắt chính, tự động biến mất sau 1-2s và thay thế tức thì không dồn đọng thông báo.
- **Thanh trạng thái Niri (Noctalia Status Bar):** Widget `keymap` trên thanh bar hiển thị nhãn chế độ thời gian thực (`NORMAL`, `NAV`, `CHROM`, `TERM`, `NIRI`, `SUPER`, `C-LOCK`), cho phép click để mở bảng tra cứu phím tắt.
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
