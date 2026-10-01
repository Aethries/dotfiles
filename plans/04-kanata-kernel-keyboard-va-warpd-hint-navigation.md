# Kế hoạch 04: Remapping Bàn phím Tầng Kernel (`kanata`) và Điều khiển Chuột Bàn phím (`warpd`)

## 1. Tên chức năng
**Nâng Cấp Thao Tác Bàn Phím Toàn Diện: Ánh Xạ Phím Tầng Kernel (`kanata`) và Điều Khiển Chuột Bằng Checkpoint Hint (`warpd`).**

---

## 2. Mô tả chức năng

### 2.1. Vấn đề hiện tại
* Người dùng phải liên tục với tay tới cụm phím mũi tên hoặc nhấc tay sang chuột để click các thành phần trên màn hình, làm giảm tốc độ code và gây mỏi cổ tay.
* CapsLock là phím ở vị trí đắc địa nhất nhưng hầu như không bao giờ dùng tới.
* Các tổ hợp phím tắt phức tạp (Ctrl, Alt, Super, Shift) đòi hỏi bẻ gập ngón tay út.
* **Thách thức kỹ thuật đặc thù:** Bộ gõ tiếng Việt Telex (`Fcitx5 Bamboo`) thường gõ các chuỗi phím lặp lại với tốc độ rất cao (như `aa`, `dd`, `as`, `ee`). Nếu cấu hình Home-row mods không chuẩn, bàn phím sẽ hiểu nhầm việc gõ nhanh là thao tác giữ phím và vô tình kích hoạt Modifier gây mất chữ hoặc nhảy phím tắt ngoài ý muốn.

### 2.2. Mục tiêu kỹ thuật
1. Cài đặt `kanata` chạy ở tầng kernel qua `/dev/uinput`:
   * **Home-row mods:** Biến hàng phím cơ sở `A`, `S`, `D`, `F` (bàn tay trái) và `J`, `K`, `L`, `;` (bàn tay phải) thành `Super`, `Alt`, `Ctrl`, `Shift` khi giữ đè; hoạt động như chữ cái bình thường khi gõ nhả nhanh.
   * **Dual-role CapsLock:** Bấm nhả là phím `Escape` (cực kỳ tiện lợi cho Neovim/Vim); bấm giữ đè hoạt động như phím `Control` (cho Terminal shortcuts).
   * **Layer Navigation:** Giữ phím `Space` để biến cụm phím `H/J/K/L` thành phím mũi tên `Trái/Xuống/Lên/Phải`, kèm `Home`, `End`, `PageUp`, `PageDown` ngay dưới đầu ngón tay.
   * **Bộ lọc tương thích Telex:** Cấu hình thuật toán `tap-hold-press` với thời gian trễ `tapping-term` (~180ms) để loại bỏ hoàn toàn hiện tượng xung đột với bộ gõ tiếng Việt Fcitx5 Bamboo.
2. Cài đặt `warpd`:
   * Trải lưới checkpoint 2 chữ cái phủ toàn bộ màn hình Wayland. Người dùng chỉ cần gõ 2 chữ cái tương ứng là con trỏ chuột sẽ lập tức nhảy đến vị trí đó và thực hiện click chuột trái/phải hoặc bắt đầu kéo thả mà không cần chạm tay vào chuột.

---

## 3. Chi tiết triển khai

### 3.1. Các file cần tạo và sửa đổi

* **[MODIFY]** [packages/aur.txt](file:///home/loc/Workspaces/dotfiles/packages/aur.txt): Thêm `kanata-bin` và `warpd`.
* **[NEW]** `modules/kanata/files/kanata.kbd`: File cấu hình layout phím, tap-hold timings và layer navigation.
* **[NEW]** `modules/kanata/files/kanata.service`: Systemd service chạy ngầm.
* **[NEW]** `modules/kanata/setup.sh`: Script thiết lập udev rules cho `/dev/uinput` và kích hoạt service.
* **[MODIFY]** [modules/umbriel/files/keybinds.toml](file:///home/loc/Workspaces/dotfiles/modules/umbriel/files/keybinds.toml): Gắn phím tắt gọi `warpd --hint`.

### 3.2. Cấu hình chi tiết `modules/kanata/files/kanata.kbd`

```lisp
;; Kanata Configuration Optimized for Programming & Vietnamese Telex
(defcfg
  process-unmapped-keys yes
  linux-dev-names-exclude ()
)

(defsrc
  caps a s d f    j k l ;
  spc
)

(defvar
  tap-time 180
  hold-time 200
)

(defalias
  ;; Dual-role CapsLock: Esc on tap, Ctrl on hold
  cap (tap-hold 160 180 esc lctl)

  ;; Left hand home-row mods
  a-met (tap-hold-press $tap-time $hold-time a lmet)
  s-alt (tap-hold-press $tap-time $hold-time s lalt)
  d-ctl (tap-hold-press $tap-time $hold-time d lctl)
  f-sft (tap-hold-press $tap-time $hold-time f lsft)

  ;; Right hand home-row mods
  j-sft (tap-hold-press $tap-time $hold-time j rsft)
  k-ctl (tap-hold-press $tap-time $hold-time k rctl)
  l-alt (tap-hold-press $tap-time $hold-time l lalt)
  ;-met (tap-hold-press $tap-time $hold-time ; rmet)

  ;; Navigation Layer on Space hold
  nav-spc (tap-hold 160 200 spc (layer-toggle nav))
)

(deflayer base
  @cap   @a-met @s-alt @d-ctl @f-sft   @j-sft @k-ctl @l-alt @;-met
  @nav-spc
)

(deflayer nav
  _      _      _      _      _        left   down   up     rght
  _
)
```

---

## 4. Hướng dẫn sử dụng

### 4.1. Thao tác gõ phím với Kanata

| Thao tác phím | Hành vi nhận diện | Tình huống sử dụng |
|---|---|---|
| Bấm nhả `CapsLock` | Phím `Escape` | Thoát chế độ Insert trong Neovim tức thì |
| Giữ `CapsLock` + `C` | Phím `Ctrl + C` | Ngắt lệnh trong terminal cực kỳ tự nhiên |
| Giữ `F` + bấm `T` | `Shift + T` (Chữ `T` hoa) | Viết hoa không cần với ngón út tới Shift |
| Giữ `D` + bấm `V` | `Ctrl + V` (Dán) | Phím tắt văn phòng không cần bẻ tay |
| Giữ `A` + bấm `Space` | `Super + Space` (Launcher) | Mở launcher ngay trên hàng phím chính |
| Giữ `Space` + `H/J/K/L` | Mũi tên `← / ↓ / ↑ / →` | Di chuyển con trỏ văn bản không rời vị trí cơ sở |

### 4.2. Điều khiển chuột bằng Warpd Hint Mode
1. Bấm tổ hợp phím **`Mod + Shift + Space`** (hoặc `Mod + H`).
2. Màn hình sẽ lập tức trải một lưới các ký tự gợi ý 2 chữ cái (ví dụ: `ab`, `cd`, `kf`...) lên các vị trí tương tác.
3. **Thao tác:**
   * Gõ 2 ký tự: Con trỏ nhảy tới vị trí đó và **Click chuột trái**.
   * Giữ `Shift` + gõ 2 ký tự: Con trỏ nhảy tới và **Click chuột phải**.
   * Giữ `Ctrl` + gõ 2 ký tự: Bắt đầu **Kéo thả chuột (Drag)**.
4. Muốn thoát chế độ: Bấm `Escape`.

---

## 5. Tiêu chuẩn kiểm thử & Nghiệm thu (Verification)

1. **Kiểm tra quyền truy cập uinput:**
   ```bash
   ls -la /dev/uinput
   # Nhóm 'input' hoặc user hiện tại phải có quyền đọc/ghi (rw)
   ```
2. **Kiểm tra tương thích tiếng Việt:**
   * Mở trình soạn thảo, bật gõ Telex (`Fcitx5 Bamboo`).
   * Gõ nhanh các từ: `"được"`, `"đường"`, `"ass"`, `"tiến độ"`, `"hoàn thành"`.
   * Chữ hiển thị mượt mà 100%, không bị nuốt chữ hoặc vô tình kích hoạt phím Super/Alt/Ctrl.
3. **Kiểm tra Warpd:**
   * Chạy `warpd --hint` từ terminal: Màn hình hiển thị các hint chữ cái vàng/đỏ nổi bật và nhảy chuột chuẩn xác.
