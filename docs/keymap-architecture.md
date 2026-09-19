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
           ▼                                  ▼
┌───────────────────────┐          ┌───────────────────────┐
│       NAV LAYER       │          │     POINTER LAYER     │
│  h/j/k/l -> Arrows    │          │  h/j/k/l -> Di chuột  │
│  w/b     -> Ctrl+Left/│          │  v/b/n   -> Click Trái│
│             Right     │          │             /Giữa/Phải│
│  0/$     -> Home/End  │          │  Warpd Hint Trigger   │
│  u/d     -> PgUp/PgDn │          └───────────────────────┘
│  x       -> Delete    │
└───────────────────────┘
```

### 3.1. Base Layer (Lớp cơ bản)
- **Home-Row Mods (HRM):**
  - Tay trái: `a` (Super), `s` (Alt), `d` (Ctrl), `f` (Shift).
  - Tay phải: `j` (Shift), `k` (Ctrl), `l` (Alt), `;` (Super).
  - *Quy chuẩn thời gian:* `tap-hold-release` với timeout 200ms, áp dụng `chord-cancel` để tránh xung đột khi gõ tiếng Việt tốc độ cao qua bộ gõ Fcitx5.
- **Phím chức năng kép (Dual-role keys):**
  - `Space`: Nhấn thả (Tap) = Phím Space thông thường. Giữ (Hold) = Kích hoạt tức thời **Nav Layer**.
  - `CapsLock`: Nhấn thả (Tap) = `Escape`. Giữ (Hold) = `Left Control` (hoặc phím kích hoạt Pointer Layer).

### 3.2. Nav / Modal Layer (Lớp điều hướng Vim)
Kích hoạt khi giữ `Space`. Toàn bộ bàn phím chuyển thành bàn phím điều hướng chuẩn Vim cho mọi app (Chrome, Slack, VSCode/Antigravity, Files):
- **Phím di chuyển cơ bản:**
  - `h` $\rightarrow$ `Left Arrow`
  - `j` $\rightarrow$ `Down Arrow`
  - `k` $\rightarrow$ `Up Arrow`
  - `l` $\rightarrow$ `Right Arrow`
- **Di chuyển theo từ & biên dòng:**
  - `w` $\rightarrow$ `Ctrl + Right Arrow` (Nhảy tới đầu từ kế tiếp)
  - `b` $\rightarrow$ `Ctrl + Left Arrow` (Nhảy về đầu từ trước)
  - `e` $\rightarrow$ `Ctrl + Right Arrow` (Tới cuối từ)
  - `0` $\rightarrow$ `Home` (Về đầu dòng)
  - `4` (`$`) $\rightarrow$ `End` (Về cuối dòng)
- **Cuộn màn hình & văn bản:**
  - `u` $\rightarrow$ `Page Up` (Cuộn nửa trang lên trên)
  - `d` $\rightarrow$ `Page Down` (Cuộn nửa trang xuống dưới)
- **Xóa & Thao tác:**
  - `x` $\rightarrow$ `Delete` (Xóa ký tự phía trước)
  - `BackSpace` $\rightarrow$ `Ctrl + BackSpace` (Xóa cả từ phía sau)

### 3.3. Pointer Layer (Lớp điều khiển con trỏ & Warpd)
Kích hoạt qua tổ hợp phím hoặc giữ `Caps` kết hợp phím bổ trợ:
- Tích hợp công cụ **Warpd** (`warpd --hint` hoặc `warpd --normal`):
  - Kích hoạt lưới tọa độ màn hình để nhảy chuột tới bất kỳ điểm nào bằng 2-3 phím bấm.
- Điều khiển con trỏ mịn bằng `h/j/k/l` nếu cần tinh chỉnh micro-step.
- Các nút chuột mô phỏng:
  - `v` $\rightarrow$ Chuột trái (Left click / Drag)
  - `b` $\rightarrow$ Chuột giữa (Middle click)
  - `n` $\rightarrow$ Chuột phải (Right click)

### 3.4. Bypass & Emergency Recovery Layer (Lớp thoát hiểm)
Ngăn chặn hoàn toàn rủi ro bị khóa phím (lockout) hoặc vướng tap-hold khi chơi game/dùng VM:
- **Tổ hợp phần cứng (Hardware Chord):** Nhấn đồng thời `Left Shift + Right Shift` (hoặc `Super + Backspace`).
- **Hành vi:**
  - Kanata phát tín hiệu chuyển thẳng sang layer `raw-passthrough`.
  - Tắt toàn bộ intercept, tắt Home-Row Mods, tắt modal Space.
  - Bàn phím hoạt động như bàn phím USB thuần 100%.
  - Nhấn lại tổ hợp để bật lại chế độ làm việc thông minh.

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
