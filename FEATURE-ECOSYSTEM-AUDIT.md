# Audit feature và hệ sinh thái cho máy cá nhân

## Phạm vi

Audit này tập trung vào các feature, công cụ và tích hợp còn thiếu trong bộ dotfiles dùng trên máy cá nhân và remote workstation. Các hạng mục tài liệu, test, CI và rollback không thuộc phạm vi ưu tiên của bản này.

## Hiện trạng đã có

- Shell: Zsh, Oh My Zsh, autosuggestions, syntax highlighting, Starship, Zoxide, Yazi và các alias tiện ích.
- Terminal: Kitty kết hợp Zellij, launcher chọn session bằng FZF.
- Desktop: Umbriel compositor, greetd, Noctalia greeter, Fcitx5 Bamboo, fontconfig, PipeWire và WirePlumber.
- Developer tooling: Node.js/NVM, npm global packages, Docker, lazygit, lazydocker, ripgrep, fd, jq, yq.
- AI: 9router local gateway, Antigravity IDE/CLI, cấu hình MITM CA và systemd user service.
- Network: NetworkManager, Cloudflare WARP, cloudflared và helper tạo tunnel.
- Credentials: gnome-keyring/libsecret, age, vault backup cho một số profile ứng dụng.
- Desktop applications: Chrome, Telegram, Slack, Lark, Obsidian, Postman, Beekeeper Studio.

## Đánh giá mức độ bao phủ techstack hiện tại

Hiện tại, hệ thống dotfiles đã hoàn thiện tốt phần lõi terminal (Zsh + Kitty + Zellij), compositor (Umbriel), input method (Fcitx5 Bamboo), AI gateway (9router, Antigravity) và các ứng dụng GUI cơ bản. Tuy nhiên, độ phủ thực tế đối với công việc hằng ngày mới đạt **~50%**, chưa đạt mốc workstation hoàn chỉnh.

Các khoảng trống và điểm nghẽn lớn nhất bao gồm:
1. **Modules cấu hình cốt lõi còn rỗng hoặc bị thiếu**:
   - `modules/noctalia`: Thư mục cấu hình Noctalia shell hiện chưa có trong repo, dẫn đến symlink `~/.config/noctalia/config.toml` trên máy bị hỏng. Gói `noctalia` cũng chưa có trong danh sách cài đặt AUR.
   - `modules/nvim`: Mới chỉ là khung thư mục rỗng, chưa có bất kỳ file Lua cấu hình nào (chưa có LSP, Treesitter, plugin manager).
   - `modules/git`: Mới chỉ là thư mục rỗng, chưa có file `.gitconfig` chuẩn, chưa cấu hình commit signing, chưa có credential helper, chưa có `includeIf` và hook nạp `.gitconfig.local`.
   - `modules/umbriel`: Mới có cấu hình cơ bản, thiếu window rules chuyên sâu cho dialog/IDE, chưa gắn phím tắt cho media/OSD và các công cụ điều khiển nhanh.
2. **Biến môi trường cấp Desktop Session (`environment.d`)**: Các biến quan trọng như Wayland Ozone, WebRTC capturer, Fcitx5 mới chỉ nằm trong `.zshrc`. Khi mở ứng dụng từ Launcher hoặc phím tắt compositor, ứng dụng không nhận diện được các biến này.
3. **Runtime Management**: Hiện chỉ có NVM cho Node.js; thiếu môi trường cho Python, Rust, Go và chưa có công cụ quản lý runtime đa ngôn ngữ hiện đại (`mise`) kết hợp `uv`.
4. **Cloud & Database Workflows**: Thường xuyên làm việc với AWS, GCP và database nhưng chưa có các CLI chuyên dụng (`aws-cli`, `granted`, `google-cloud-cli`, `gke-gcloud-auth-plugin`, `opentofu`/`terraform`, `usql`, `pgcli`, `iredis`).
5. **Wayland Desktop Usability**: Thiếu clipboard history (`cliphist`), thiếu cấu hình cờ WebRTC PipeWire Screen Sharing cho Chrome/Electron, và chưa tích hợp sâu các tính năng sẵn có của Noctalia.
6. **Thao tác bàn phím nâng cao**: Chưa có keyboard remapping mức kernel (`kanata`) và công cụ trải checkpoint hint để nhảy chuột/click bằng bàn phím (`warpd`), cần lưu ý tránh xung đột với bộ gõ tiếng Việt.
7. **Remote Desktop để code**: Đã có ý tưởng Sunshine/Tailscale nhưng cần giải pháp headless display ổn định (ưu tiên phần cứng HDMI Dummy Plug) và client workflow tối ưu.

---

## Các feature còn thiếu, theo mức độ hữu ích

### P0 — nên bổ sung trước

#### 1. Clipboard manager

Fcitx5 và `wl-copy` chỉ cung cấp clipboard hiện tại; chưa có lịch sử clipboard. Bổ sung `cliphist` (kết hợp `wl-clipboard` và Noctalia launcher / FZF), kèm phím tắt mở lịch sử và cơ chế loại trừ dữ liệu nhạy cảm từ password manager qua systemd user service (`wl-paste --watch cliphist store`).

Lợi ích:
- Khôi phục nhiều mục đã copy (cả text và image).
- Tìm lại lệnh, mã xác nhận và đoạn văn bản.
- Hoạt động tốt với Kitty, Chrome, IDE và terminal.

#### 2. Noctalia Desktop Shell & Notification Center

Hệ thống đã có `noctalia` 5.1 chạy cùng Umbriel nhưng chưa được quản lý bằng module dotfiles. Khôi phục `modules/noctalia` để tận dụng hệ thống quản trị desktop hợp nhất:
- Notification Daemon chuẩn DBus (`org.freedesktop.Notifications`), quản lý Do Not Disturb, phân loại urgency, notification history và panel thông báo chuyên dụng (`noctalia msg notification-dnd-toggle`, `panel-toggle notifications`).
- OSD hiển thị trực quan cho âm lượng, độ sáng và microphone.
- Khắc phục tình trạng broken symlink `~/.config/noctalia/config.toml` và bổ sung `noctalia` vào [packages/aur.txt](file:///home/loc/Workspaces/dotfiles/packages/aur.txt).

#### 3. Screenshot, screen recording và annotation tích hợp

Tận dụng công cụ chụp và chú thích tích hợp sẵn của Noctalia kết hợp công cụ quay video màn hình:
- Chụp ảnh và chú thích tức thì qua `noctalia msg screenshot-annotate` (đóng băng màn hình và vẽ mũi tên, khung viền, che mờ thông tin nhạy cảm trước khi lưu hoặc copy vào clipboard).
- Chụp nhanh vùng chọn bằng `noctalia msg screenshot-region` hoặc toàn màn hình bằng `noctalia msg screenshot-fullscreen`.
- Gắn các lệnh trên vào phím tắt compositor Umbriel (ví dụ `Print`, `Mod+Shift+S`).
- Quay màn hình tối ưu GPU định dạng nhẹ bằng `wl-screenrec`.

#### 4. Quản lý power và laptop hardware

Tích hợp UPower và `power-profiles-daemon` thông qua Noctalia:
- Điều khiển profile năng lượng nhanh: `noctalia msg power-cycle` hoặc `power-set` (Performance, Balanced, Power saver).
- Điều khiển độ sáng bằng `brightnessctl`.
- Cấu hình tự động khóa màn hình và giảm độ sáng khi idle.

#### 5. Bluetooth và thiết bị ngoại vi

Bổ sung quản lý Bluetooth hoàn chỉnh cho tai nghe, bàn phím và chuột không dây:
- `bluez` và `bluez-utils`.
- Blueman hoặc widget Bluetooth tích hợp trong Noctalia panel.
- Tự reconnect thiết bị quen thuộc và hiển thị phần trăm pin thiết bị.
- Profile A2DP/HFP cho tai nghe.

#### 6. Desktop portals, WebRTC screen sharing và Session Environment

Hệ thống đã có `xdg-desktop-portal-umbriel` và `xdg-desktop-portal-gtk` phục vụ ScreenCast và giao tiếp desktop. Điểm cần hoàn thiện là cấp session environment để ứng dụng GUI nhận diện đầy đủ:
- Tạo module chuẩn hóa biến môi trường `~/.config/environment.d/00-wayland.conf`:
  - `ELECTRON_OZONE_PLATFORM_HINT="auto"`
  - `XMODIFIERS="@im=fcitx"`
  - `QT_QPA_PLATFORM="wayland;xcb"`
  - `MOZ_ENABLE_WAYLAND=1`
- Cấu hình cờ Chromium/Electron tại `~/.config/chrome-flags.conf` và `~/.config/electron-flags.conf`:
  - `--ozone-platform-hint=auto`
  - `--enable-features=WaylandWindowDecorations,WebRTCPipeWireCapturer`
  - Hỗ trợ screen sharing mượt mà trong Google Meet, Slack, Lark.
- Cấu hình file associations (MIME defaults) cho editor, browser, media viewer và Yazi.

#### 7. Kanata — Keyboard remapping mức Kernel

Trình ánh xạ phím phần cứng chạy ở tầng kernel qua `/dev/uinput`, không phụ thuộc vào compositor:
- Home-row mods: Biến các phím `A`, `S`, `D`, `F` thành `Super`, `Alt`, `Ctrl`, `Shift` khi giữ đè; gõ bình thường khi bấm nhả nhanh.
- Dual-role phím CapsLock: Bấm nhả hoạt động như `Escape`, giữ đè hoạt động như `Control`.
- Layer navigation: Giữ Space để biến các phím `H/J/K/L` thành cụm mũi tên di chuyển, kèm `Home`, `End`, `PageUp`, `PageDown` ngay trên hàng cơ sở.
- Lưu ý tương thích bộ gõ tiếng Việt (Fcitx5 Bamboo): Với tốc độ gõ Telex cao, cần tinh chỉnh `tap-hold-press` hoặc `chord` và thiết lập `tapping-term` (~160-200ms) để không vô tình kích hoạt Modifier khi gõ các ký tự lặp (`aa`, `dd`, `as`...).
- **Tối ưu tốc độ lặp phím và độ nhạy Caret (Repeat Delay & Rate)**: Giảm thời gian trễ nhận phím giữ (`repeat_delay = 180ms`) và tăng tốc độ lặp (`repeat_rate = 50Hz`) trong cấu hình compositor Umbriel và virtual device của Kanata để nhận diện caret tức thì, giúp thao tác di chuyển con trỏ và xóa ký tự phản hồi mượt mà, không giật khựng.
- Triển khai: Cài `kanata-bin` (AUR), cấu hình udev rule cho `/dev/uinput`, chạy dưới dạng systemd user/system service.

#### 8. Warpd — Trải Checkpoint/Hint điều khiển chuột bằng bàn phím

Thao tác bàn phím tốc độ cao trên toàn màn hình Wayland mà không cần chạm tay vào chuột:
- **Hint Mode (`warpd --hint`)**: Trải một lưới ký tự 2 chữ cái phủ khắp màn hình. Gõ 2 ký tự tương ứng để con trỏ nhảy ngay đến vị trí đó và thực hiện click hoặc kéo thả.
- **Grid Mode & Normal Mode**: Điều khiển con trỏ mượt mà theo 4 hướng bằng `H/J/K/L`.
- **Hệ sinh thái Checkpoint đồng bộ**:
  - Desktop: `warpd` cho mọi cửa sổ ứng dụng và hệ thống.
  - Trình duyệt Chrome: Extension `Vimium C` trải hint chữ cái lên link/button.
  - Editor Neovim: Plugin `flash.nvim` nhảy 2D trên code buffer bằng checkpoint ký tự tương tự.

---

### P1 — tăng mạnh năng suất phát triển

#### 9. Git identity, GPG/SSH signing, credential helper và local override

Thư mục `modules/git` hiện tại mới chỉ là thư mục rỗng, cần hoàn thiện toàn diện:
- `modules/git/files/.gitconfig`:
  - Git Delta pager đã được cài đặt.
  - Git credential helper dùng `git-credential-libsecret` liên kết với GNOME Keyring.
  - Commit signing tự động bằng SSH key `ed25519` (`commit.gpgsign = true`).
  - Hỗ trợ GPG signing an toàn với `pinentry-curses` hoặc `pinentry-gnome3` cho Wayland.
  - Phân tách email công việc và cá nhân bằng directive `[includeIf "gitdir:~/Workspaces/work/"]`.
- Cơ chế ghi đè cục bộ (Local Override):
  - Tự động nạp `~/.gitconfig.local` và `~/.zshrc.local`.
  - Đưa các file `.local` vào `.gitignore` của dotfiles.
- Bảo mật secrets: Tích hợp `gitleaks` vào pre-commit hooks để ngăn chặn việc commit nhầm khóa bí mật, token, key API lên Git.

#### 10. `mise` kết hợp `uv` — Quản lý Runtime đa ngôn ngữ hiện đại

Thay thế việc quản lý phân mảnh và chậm chạp của NVM bằng `mise-en-place` (`mise`):
- Viết bằng Rust, shim siêu tốc, loại bỏ độ trễ khi mở shell mới.
- Quản lý tập trung: Node.js, Python, Rust, Go, Bun, Terraform/OpenTofu, AWS CLI, pnpm.
- Tự động chuyển đổi version theo file cấu hình dự án (`.mise.toml`, `package.json`, `.python-version`).
- Kết hợp **`uv`** cho Python: Thay thế pip/virtualenv truyền thống bằng `uv` để tạo venv và cài đặt thư viện Python với tốc độ tức thì.
- Cấu hình kích hoạt trong `.zshrc`: `eval "$(mise activate zsh)"`.

#### 11. Cloud Tooling: AWS & GCP Workflow

Chuẩn hóa các công cụ làm việc với hạ tầng đám mây:
- **AWS**:
  - `aws-cli-v2`.
  - `granted` (cung cấp lệnh `assume`): Chuyển đổi giữa nhiều tài khoản/vai trò AWS SSO tức thì trên terminal và mở session trình duyệt tách biệt.
  - `aws-session-manager-plugin`: Kết nối SSH trực tiếp vào EC2 thông qua SSM không cần mở port 22.
- **GCP**:
  - `google-cloud-cli` (`gcloud`).
  - `gke-gcloud-auth-plugin`: Xác thực bắt buộc cho `kubectl` tới GKE clusters.
  - Cấu hình Application Default Credentials (ADC) phục vụ chạy code local gọi Google Cloud APIs (`gcloud auth application-default login`).
- **Infrastructure as Code (IaC)**:
  - `opentofu` (hoặc `terraform`), kết hợp `terragrunt` để quản lý hạ tầng đa môi trường.

#### 12. Database CLI & Remote Tunneling

Bên cạnh Beekeeper Studio (GUI), bổ sung CLI tốc độ cao cho terminal và scripting:
- `usql`: Universal SQL CLI hỗ trợ PostgreSQL, MySQL, SQLite, Oracle, ClickHouse, SQL Server với auto-completion và syntax highlighting.
- `pgcli`: CLI chuyên biệt cho PostgreSQL với gợi ý cú pháp và schema thông minh.
- `iredis`: CLI cho Redis với auto-completion lệnh và key.
- Helper kết nối bảo mật: Tận dụng Tailscale hoặc script port-forwarding SSH tunnel (`ssh -L`) để truy cập private instance từ xa.

#### 13. Tailscale và remote network mesh

Bổ sung Tailscale vào lớp remote access cho máy cá nhân, VPS, laptop và điện thoại:
- MagicDNS, hostname cố định.
- Tailscale SSH với ACL riêng, xác thực mượt mà không cần sao chép khóa thủ công.
- Subnet routing và exit node tùy chọn.
- Helper kiểm tra trạng thái node, IP tailnet và độ trễ mạng.

#### 14. 9remote qua npm

Bổ sung `9remote` vào hệ thống công cụ remote:
- Hỗ trợ kết nối tới host trong tailnet, chọn host bằng hostname, mở terminal, port forwarding, remote command, SSH agent.
- Cung cấp các lệnh tiện ích: `remote <host>`, `remote-shell <host>` và `remote-forward <host> <port>`.

#### 15. Sunshine và remote desktop chuyên sâu cho lập trình

Giải pháp remote vào máy trạm để code từ xa (từ laptop, tablet) với độ trễ thấp và phần cứng tối ưu:
- **Host (Máy trạm)**:
  - Cài đặt `sunshine` chạy dưới dạng systemd user service, tận dụng GPU hardware encoder (NVENC hoặc VAAPI).
  - **Headless Display thực dụng**: Khuyến nghị sử dụng **HDMI Dummy Plug 4K** (phần cứng giá rẻ cắm vào GPU) giúp máy stream ổn định ở 2K/4K 60-120Hz ngay cả khi màn hình chính tắt, tránh lỗi driver phức tạp của màn hình ảo phần mềm trên Wayland.
  - Ràng buộc Sunshine chỉ lắng nghe trên IP nội bộ của Tailscale.
  - Cấu hình audio PipeWire, microphone, clipboard hai chiều và tự động khóa màn hình khi client disconnect.
- **Client**: Cài đặt Moonlight (Moonlight-qt) trên thiết bị kết nối.
- Hỗ trợ thêm VS Code Remote Tunnels / Remote SSH qua Tailscale khi chỉ có nhu cầu chỉnh sửa mã nguồn mà không cần stream toàn bộ giao diện desktop.

#### 16. Python, Rust, Go và container development

Hoàn thiện toolchain lập trình:
- Python: `uv`, `pipx`.
- Rust toolchain: `cargo`, `clippy`, `rustfmt`, `rust-analyzer`.
- Go: `gopls`, `delve`.
- Container tools: `docker-compose`, `docker-buildx`, `hadolint`, `dive`, `trivy`.
- Script dọn dẹp tài nguyên Docker định kỳ.

#### 17. VS Code bản mới và editor ecosystem

Bổ sung VS Code bản mới theo nguồn ổn định song song với Antigravity IDE:
- Profile cấu hình: local, remote SSH, dev container.
- Settings Sync, Remote Tunnels.
- Terminal profile mặc định dùng Zsh và Zellij.
- Font, theme và keybindings đồng bộ với toàn hệ thống.

#### 18. Theme system đồng bộ qua Noctalia

Thay vì bảo trì các file theme riêng lẻ, tận dụng engine tạo màu của Noctalia:
- Noctalia hỗ trợ tạo palette tự động từ ảnh nền (`noctalia theme <image>`) và chuyển đổi chế độ (`noctalia msg theme-mode-toggle`).
- Dùng cơ chế `templates-apply` của Noctalia để xuất màu đồng bộ sang Kitty, Zellij, Neovim, VS Code, delta và starship.
- Đảm bảo nhất quán: background, foreground, accent, semantic colors (error/warning/success/info), border và cursor.

#### 19. Hoàn thiện cấu hình Noctalia và Umbriel

Cả hai module giao diện hiện đều cần bổ sung cấu hình chi tiết:
- **`modules/noctalia`**:
  - Khôi phục thư mục module và file `config.toml`.
  - Cấu hình bar/widgets, launcher, notification center, power menu, wallpaper, lock screen, OSD.
  - Thiết lập phím tắt gọi các bảng điều khiển panel qua `noctalia msg`.
- **`modules/umbriel`**:
  - Mở rộng [modules/umbriel/files/config.toml](file:///home/loc/Workspaces/dotfiles/modules/umbriel/files/config.toml): bổ sung window rules cho các ứng dụng nổi (float dialogs, file pickers, terminal scratchpads), quy tắc tỉ lệ scrolling layout cho IDE và browser.
  - Mở rộng [modules/umbriel/files/keybinds.toml](file:///home/loc/Workspaces/dotfiles/modules/umbriel/files/keybinds.toml): bổ sung phím tắt chụp màn hình (`noctalia msg screenshot-annotate`), mở clipboard history, điều khiển âm lượng/độ sáng, và kích hoạt Warpd hint mode.

#### 20. Neovim ecosystem module

Thư mục `modules/nvim` hiện tại đang rỗng, cần xây dựng cấu hình editor chuẩn:
- Quản lý plugin bằng `lazy.nvim`.
- Quản lý LSP, linter, formatter tự động qua `mason.nvim` và `mason-lspconfig.nvim`.
- Treesitter cho syntax highlighting chính xác.
- Fuzzy finder: `telescope.nvim` hoặc `snacks.nvim`.
- Điều hướng checkpoint ký tự: `flash.nvim` (đồng bộ trải nghiệm với Warpd và Vimium C).
- Git integration: `gitsigns.nvim`.
- Hỗ trợ ngôn ngữ: Lua, Bash, Nix, JSON, TOML, YAML, TypeScript, Python, Rust, Go, Markdown.
- Đồng bộ theme, font JetBrains Mono Nerd Font và phím tắt mở Zellij/terminal.

#### 21. SSH như chạy trên máy local

Bổ sung lớp remote filesystem và remote development:
- Cấu hình SSH: `ControlMaster`, `ControlPersist`, keepalive.
- `sshfs` hoặc systemd user mount dưới `~/mnt/remote/<host>`.
- Các helper commands:
  - `ssh-mount <host> [path]`
  - `ssh-umount <host>`
  - `ssh-sync <host> <local> <remote>`
  - `ssh-forward <host> <local-port> <remote-port>`
  - `ssh-project <host> <path>`
- Kết hợp `mosh` cho các kết nối mạng chập chờn khi di chuyển.

#### 21b. AI Developer Tooling & Agentic Engineering

Tối ưu hóa môi trường lập trình cùng AI cho Antigravity IDE và Gemini CLI:
- **AG Kit (`.agents/`)**: Hệ thống Agent, Skills, Rules và Memory cross-session đồng bộ hóa phong cách pair programming.
- **Ponytail Principle**: Tiêu chuẩn code YAGNI cực hạn — minimal working diff, tái sử dụng abstraction sẵn có, hạn chế tối đa over-engineering và code thừa.
- **RTK Ultra**: Token compression, tự động lọc nhiễu stdout/stderr từ terminal (build logs, test outputs) trước khi đưa vào context window của LLM.
- **Caveman Communication**: Giao thức phản hồi cô đọng tối đa, loại bỏ từ ngữ xã giao, phản hồi theo mô hình telegraphic `[thing] [action] [reason]. [next step].`
- **CodeGraph MCP**: Local MCP server phân tích cấu trúc AST Tree-sitter + SQLite, tính toán chính xác blast radius của thay đổi mà không cần nạp toàn bộ repo.
- **Codebase MCP**: Index bộ nhớ symbol nhanh, tra cứu định nghĩa và phụ thuộc không tiêu hao context.

---

### P2 — hoàn thiện desktop experience

#### 22. Launcher và application runner

Tối ưu hóa launcher của Noctalia làm giao diện chính:
- Mở ứng dụng nhanh.
- Tìm kiếm file và thư mục.
- Tích hợp clipboard history qua `cliphist`.
- SSH host picker và power actions.
- Cấu hình FZF trong terminal làm fallback launcher linh hoạt.

#### 23. Wallpaper, lock screen và idle manager

- Quản lý wallpaper thông qua Noctalia (`noctalia msg wallpaper-set`).
- Cấu hình tự động khóa màn hình sau thời gian không hoạt động.
- Tự động tắt màn hình (DPMS off) và suspend máy khi không sử dụng.
- Khóa màn hình trước khi máy vào trạng thái suspend hoặc đóng nắp laptop.

#### 24. Audio control và media keys

- Quản lý audio qua PipeWire và WirePlumber.
- Điều khiển Play/Pause/Next/Previous và hiển thị OSD thông qua Noctalia media commands.
- Chuyển đổi nhanh output tai nghe/loa ngoài và microphone.
- Giao diện GUI mixer: `pavucontrol` hoặc `pwvucontrol` khi cần điều chỉnh nâng cao.

#### 25. File manager integration

Hoàn thiện trải nghiệm Yazi trong terminal:
- Preview ảnh, video và PDF trực tiếp trong Kitty terminal (`chafa`, `imagemagick`).
- Nén và giải nén archive nhanh.
- Tích hợp Trash CLI (`trash-cli`).
- Open-with theo danh mục MIME mặc định.

#### 26. PDF, image và media tools

- Trình xem tài liệu PDF nhẹ trên Wayland: `zathura` (kèm plugin `zathura-pdf-mupdf`).
- Terminal preview: `chafa`.
- Media playback và xử lý video: `mpv`, `ffmpeg`, `yt-dlp`.
- Trình xem ảnh Wayland: `imv`.

#### 27. Removable media và file transfer

- Tự động mount ổ đĩa USB/ổ cứng ngoài qua `udiskie`.
- Hỗ trợ thiết bị Android qua MTP.
- Thông báo mount/unmount qua Noctalia notification.

---

### P3 — networking và remote workflow

#### 28. DNS, VPN và remote access

- Quản lý mạng nội bộ và tunnel qua Tailscale và Cloudflare WARP.
- Công cụ kiểm tra và chẩn đoán mạng: `wireguard-tools`, `mtr`, `nmap`, `tcpdump`, `socat`.
- Quản lý DNS phân giải nội bộ với `systemd-resolved` khi cần.

#### 29. Firewall và network visibility

- Firewall: `ufw` quản lý các port mở local.
- Helper liệt kê port đang lắng nghe (mở rộng từ `ports` alias hiện tại).
- Công cụ debug HTTP/TLS: `curl`, `httpie`.

#### 30. Sync và backup dữ liệu cá nhân (YAGNI)

Tối giản theo nhu cầu thực tế:
- **Dotfiles & Code**: Đẩy lên GitHub private repositories.
- **Secrets & Credentials**: Tận dụng module `modules/vault` (Age encryption) có sẵn trong repo.
- **Ghi chú cá nhân (Obsidian)**: Đồng bộ qua Git plugin hoặc Syncthing giữa các máy cá nhân.

---

### P4 — tiện ích vận hành hằng ngày

#### 31. System health và cleanup

Helper script cho vận hành hệ thống:
- Dọn dẹp cache Pacman định kỳ (`paccache`).
- Dọn dẹp orphan packages.
- Dọn dẹp dung lượng Docker (`docker system prune`).
- Kiểm tra dung lượng journal log (`journalctl --vacuum-time`).
- Giám sát tình trạng pin và nhiệt độ phần cứng.

#### 32. Calendar, reminders và notes

- Obsidian workflow phục vụ ghi chú công việc.
- Tìm kiếm nhanh ghi chú từ terminal bằng `ripgrep` và `fzf`.

#### 33. Browser ecosystem

Hoàn thiện môi trường Chrome:
- Quản lý profile tách biệt (`chrome-work`, `chrome-personal`).
- Extension `Vimium C` để duyệt web bằng bàn phím.
- Đồng bộ cờ bảo mật và lưu trữ mật khẩu qua GNOME Keyring.

---

## Danh sách package bổ sung vào hệ thống

Danh sách gói được tinh lọc, loại bỏ các công cụ trùng lặp và giữ lại các thành phần tương thích nhất:

```text
# Desktop / Wayland / Checkpoint Navigation
noctalia (AUR)
cliphist
wl-screenrec
brightnessctl
playerctl
pavucontrol
kanata-bin (AUR)
warpd (AUR)

# Hardware & Power
bluez
bluez-utils
blueman
power-profiles-daemon
udiskie

# Developer Runtime & CLI
mise
uv
docker-compose
docker-buildx
git-delta

# Cloud & Database CLI
aws-cli-v2
granted-bin (AUR)
google-cloud-cli (AUR/Pacman)
gke-gcloud-auth-plugin (AUR)
opentofu
usql-bin (AUR)
pgcli
iredis

# Remote Desktop & Network
tailscale
sunshine (AUR)
moonlight-qt
wireguard-tools
mtr
nmap
httpie

# Credentials, Security & Pinentry
gitleaks
pinentry-gnome3
gnupg

# Media & Viewer
zathura
zathura-pdf-mupdf
imv
mpv
ffmpeg
yt-dlp
chafa
```

---

## Thứ tự nên triển khai

1. **Khôi phục `modules/noctalia`** (sửa broken symlink, quản lý notification, OSD, screenshot native) và hoàn thiện cấu hình **`modules/umbriel`** (window rules, keybinds).
2. **Chuẩn hóa biến môi trường session** (`~/.config/environment.d/00-wayland.conf`) và cờ WebRTC screen sharing cho Chrome/Electron.
3. **Kanata keyboard remapping** (tinh chỉnh tránh xung đột Fcitx5 Bamboo) và **Warpd hint navigation**.
4. **Clipboard history (`cliphist`)** tích hợp vào Noctalia Launcher / FZF.
5. **Hoàn thiện `modules/git`** (`.gitconfig`, SSH signing `ed25519`, credential helper, local override hook, `gitleaks`).
6. **Thay thế NVM bằng `mise`** và tích hợp **`uv`** cho Python.
7. **Cloud CLI** (AWS, GCP, OpenTofu) và **Database CLI** (`usql`, `pgcli`, `iredis`).
8. **Tailscale mesh network** và thiết lập **Sunshine remote desktop** (kèm HDMI Dummy Plug 4K).
9. **Hoàn thiện `modules/nvim`** (Lazy.nvim, Mason, Treesitter, `flash.nvim`).
10. **Đồng bộ theme** bằng cơ chế template của Noctalia sang Kitty, Zellij và Neovim.
11. **AI Developer Tooling & Agentic Workflow** (tích hợp AG Kit, Ponytail YAGNI, RTK Ultra token compression, Caveman mode, CodeGraph MCP & Codebase MCP).

---

## Lộ trình triển khai thực tế

### Giai đoạn 1 — Wayland Desktop Stability & Core Ergonomics

1. Khôi phục thư mục `modules/noctalia/` với file `config.toml`, sửa broken symlink `~/.config/noctalia/config.toml`, bổ sung `noctalia` vào `packages/aur.txt`.
2. Tạo module `modules/env/` quản lý `~/.config/environment.d/00-wayland.conf` thiết lập biến môi trường Wayland, Ozone, Fcitx5 cấp session.
3. Bổ sung cờ WebRTC PipeWire vào `~/.config/chrome-flags.conf` và `~/.config/electron-flags.conf` để hỗ trợ screen sharing trong Slack, Lark, Chrome.
4. Cập nhật `modules/umbriel/files/config.toml` và `keybinds.toml`:
   - Cấu hình repeat delay (`180ms`) và repeat rate (`50Hz`) cho trải nghiệm caret nhạy mượt.
   - Gắn phím tắt chụp ảnh / chú thích qua `noctalia msg screenshot-annotate`.
   - Gắn phím tắt điều khiển âm lượng, microphone OSD.
   - Thêm window rules cho float windows và dialogs.
5. Cài đặt `cliphist`, chạy listener qua systemd user service và tích hợp vào Noctalia launcher / FZF.
6. Tạo module `modules/kanata/`: cấu hình `kanata.kbd` (home-row mods với `tap-hold-press` tương thích Fcitx5 Bamboo, dual-role CapsLock, layer navigation), udev rules cho `/dev/uinput` và systemd service.
7. Cài đặt `warpd`, gán phím tắt gọi Hint Mode trong Umbriel keybinds.

### Giai đoạn 2 — Developer Tooling, Runtime, Cloud và Database

1. Hoàn thiện `modules/git/`:
   - Quản lý `.gitconfig` chuẩn (Delta pager, `git-credential-libsecret`, commit signing bằng khóa `ed25519`, `includeIf` theo thư mục).
   - Hook tự động nạp `~/.gitconfig.local` và `~/.zshrc.local` (nằm trong `.gitignore`).
   - Cài đặt `gitleaks` và thiết lập hook ngăn chặn commit secret.
2. Thêm `mise` và `uv` vào package list. Loại bỏ đoạn nạp NVM trong `.zshrc`, chuyển sang `eval "$(mise activate zsh)"`. Tạo file cấu hình `~/.config/mise/config.toml` mặc định.
3. Cài đặt và cấu hình Cloud CLI: `aws-cli-v2`, `granted-bin`, `google-cloud-cli`, `gke-gcloud-auth-plugin`, `opentofu`.
4. Cài đặt các công cụ Database CLI: `usql-bin`, `pgcli`, `iredis`.

### Giai đoạn 3 — Remote Access và Remote Desktop Headless

1. Thêm `tailscale` vào package list, tạo module `modules/tailscale/setup.sh` kích hoạt service và cấu hình Tailscale SSH.
2. Cấu hình SSH: `ControlMaster`, `ControlPersist`, keepalive và alias theo host Tailscale.
3. Tạo helper scripts quản lý SSHFS (`ssh-mount`, `ssh-umount`, `ssh-sync`, `ssh-forward`).
4. Thiết lập Sunshine cho máy trạm:
   - Cài đặt `sunshine`, cấu hình systemd user service.
   - Sử dụng HDMI Dummy Plug 4K làm headless virtual output trên GPU vật lý.
   - Ràng buộc Sunshine chỉ lắng nghe trên IP Tailscale nội bộ.
5. Cài đặt Moonlight-qt trên client kết nối.

### Giai đoạn 4 — Editor Ecosystem và Đồng bộ Theme

1. Hoàn thiện `modules/nvim/`:
   - Cấu hình `init.lua`, `lazy.nvim`.
   - Cấu hình LSP qua Mason, formatters, linters, Treesitter.
   - Cấu hình `telescope.nvim` / `snacks.nvim` và `flash.nvim`.
2. Tạo profile VS Code chuẩn cho local và remote development.
3. Cấu hình Noctalia template engine (`noctalia msg templates-apply`) để xuất màu đồng bộ tự động sang Kitty (`kitty.conf`), Zellij (`config.kdl`) và Neovim.

### Giai đoạn 5 — AI Developer Tooling & Agentic Workflow

1. Cấu hình CodeGraph MCP (Tree-sitter SQLite AST) và Codebase MCP vào Antigravity IDE và Gemini CLI.
2. Chuẩn hóa bộ quy tắc AG Kit (`.agents/rules/`, `.agents/skills/`, `.agents/memory/`).
3. Tích hợp bộ lọc terminal RTK Ultra giảm hao phí token khi build/test.
4. Áp dụng phong cách phản hồi Caveman và tiêu chuẩn Ponytail YAGNI cho toàn bộ luồng sinh mã.

---

### Các điểm cần xác nhận trước khi triển khai package

- **Noctalia**: Xác nhận giao diện bar, widgets và launcher hiện tại đang hoạt động ổn định trên máy để export cấu hình chuẩn vào `modules/noctalia/files/config.toml`.
- **Kanata**: Xác nhận danh sách event device của bàn phím vật lý trong `/dev/input/by-id/` và layout phím (ANSI hay ISO).
- **GPU cho Sunshine**: Xác nhận card đồ họa chính của máy (Nvidia hay AMD/Intel) để cấu hình đúng encoder (NVENC hoặc VAAPI).
- **Headless Display**: Xác nhận việc sử dụng HDMI Dummy Plug hay muốn cấu hình virtual display driver.
- **Git Identity**: Xác nhận thông tin email mặc định cho cá nhân và đường dẫn thư mục công việc cho `includeIf`.
- **VS Code**: Xác nhận sử dụng `visual-studio-code-bin` hay dùng Antigravity IDE làm editor chính thức.
