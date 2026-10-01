# Audit feature và hệ sinh thái cho máy cá nhân

## Phạm vi

Audit này tập trung vào các feature, công cụ và tích hợp còn thiếu trong bộ dotfiles dùng trên máy cá nhân và remote workstation. Các hạng mục tài liệu, test, CI và rollback không thuộc phạm vi ưu tiên của bản này.

## Hiện trạng đã có

- Shell: Zsh, Oh My Zsh, autosuggestions, syntax highlighting, Starship, Zoxide, Yazi và các alias tiện ích.
- Terminal: Kitty kết hợp Zellij, launcher chọn session bằng FZF.
- Desktop: Umbriel, greetd, Noctalia greeter, Fcitx5 Bamboo, fontconfig, PipeWire và WirePlumber.
- Developer tooling: Neovim, Node.js/NVM, npm global packages, Docker, lazygit, lazydocker, ripgrep, fd, jq, yq.
- AI: 9router local gateway, Antigravity IDE/CLI, cấu hình MITM CA và systemd user service.
- Network: NetworkManager, Cloudflare WARP, cloudflared và helper tạo tunnel.
- Credentials: gnome-keyring/libsecret, age, vault backup cho một số profile ứng dụng.
- Desktop applications: Chrome, Telegram, Slack, Lark, Obsidian, Postman, Beekeeper Studio.

## Đánh giá mức độ bao phủ techstack hiện tại

Hiện tại, hệ thống dotfiles đã hoàn thiện tốt phần lõi terminal (Zsh + Kitty + Zellij), compositor (Umbriel + Noctalia), input method (Fcitx5 Bamboo), AI gateway (9router, Antigravity) và các ứng dụng GUI cơ bản. Tuy nhiên, độ phủ thực tế đối với công việc hằng ngày mới đạt **~50-60%**, chưa đủ mốc 90%.

Các khoảng trống lớn nhất bao gồm:
1. **Developer Identity & Git**: Thiếu `.gitconfig` chuẩn, chưa có commit signing, chưa cấu hình libsecret credential helper cho Git, thiếu cơ chế tách biệt email/profile cá nhân và công việc (`includeIf`), thiếu hook ghi đè cấu hình local (`.gitconfig.local`, `.zshrc.local`).
2. **Runtime Management**: Hiện chỉ có NVM cho Node.js; thiếu môi trường cho Python, Rust, Go và chưa có công cụ quản lý runtime đa ngôn ngữ hiện đại (`mise`).
3. **Cloud & Database Workflows**: Thường xuyên làm việc với AWS, GCP và database nhưng chưa có các CLI chuyên dụng (`aws-cli`, `granted`, `google-cloud-cli`, `gke-gcloud-auth-plugin`, `opentofu`/`terraform`, `usql`, `pgcli`, `iredis`).
4. **Wayland Desktop Usability**: Thiếu clipboard history (`cliphist`), thiếu công cụ chụp/ghi chú màn hình (`grim`, `slurp`, `swappy`), và thiếu WebRTC Screen Sharing Portal (`xdg-desktop-portal-wlr`) khiến không thể share màn hình trong Slack, Lark, Google Meet.
5. **Thao tác bàn phím nâng cao**: Chưa có keyboard remapping mức kernel (`kanata`) và công cụ trải checkpoint hint để nhảy chuột/click bằng bàn phím (`warpd`).
6. **Remote Desktop để code**: Đã có ý tưởng Sunshine/Tailscale nhưng chưa giải quyết bài toán headless display khi máy bàn không bật màn hình vật lý, và thiếu client workflow tối ưu.
7. **Editor Configuration**: Neovim mới chỉ cài đặt binary thô, chưa có cấu hình LSP, Treesitter, plugin ecosystem trong repo.

---

## Các feature còn thiếu, theo mức độ hữu ích

### P0 — nên bổ sung trước

#### 1. Clipboard manager

Fcitx5 và `wl-copy` chỉ cung cấp clipboard hiện tại; chưa có lịch sử clipboard. Nên thêm một clipboard manager Wayland như `cliphist` (kết hợp `wl-clipboard` và FZF/Noctalia launcher) hoặc CopyQ, kèm phím tắt mở lịch sử và cơ chế loại trừ dữ liệu nhạy cảm từ password manager.

Lợi ích:

- Khôi phục nhiều mục đã copy (cả text và image).
- Tìm lại lệnh, mã xác nhận và đoạn văn bản.
- Hoạt động tốt với Kitty, Chrome, IDE và terminal.

#### 2. Notification daemon

Repo chưa có notification daemon hoặc cấu hình notification center rõ ràng. Nên bổ sung mako, swaync hoặc notification component tương ứng của Noctalia.

Nên có:

- Do Not Disturb.
- Thông báo theo urgency.
- History.
- Âm lượng và timeout riêng cho từng loại.
- Phím tắt mở notification center.

#### 3. Screenshot, screen recording và annotation

Chưa có workflow chụp màn hình/quay màn hình hoàn chỉnh. Nên thêm grim/slurp hoặc công cụ tương đương, kèm swappy hoặc satty để vẽ chú thích nhanh, cùng wl-screenrec/OBS cho recording.

Nên tích hợp:

- Chụp toàn màn hình.
- Chụp vùng chọn.
- Chụp cửa sổ hiện tại.
- Tự copy vào clipboard và lưu vào `~/Pictures/Screenshots` theo timestamp.
- Chú thích nhanh (mũi tên, khung viền, che mờ thông tin nhạy cảm qua `swappy`/`satty`) trước khi gửi lên Slack/Lark.
- Quay màn hình video định dạng nhẹ, tối ưu GPU bằng `wl-screenrec`.
- Upload nhanh nếu người dùng cần chia sẻ.

#### 4. Quản lý power và laptop hardware

Danh sách hiện chưa thể hiện một lớp quản lý laptop hoàn chỉnh. Nên cân nhắc auto-cpufreq hoặc TLP, thermald, brightnessctl, playerctl và một frontend cho battery/power profile.

Nên có các profile:

- Performance.
- Balanced.
- Power saver.
- Tự chuyển profile khi cắm/rút sạc.
- Tự giảm brightness và khóa màn hình khi idle.

#### 5. Bluetooth và thiết bị ngoại vi

Chưa thấy BlueZ, blueman hoặc một workflow quản lý Bluetooth. Nếu máy dùng tai nghe, bàn phím hoặc chuột không dây, đây là phần còn thiếu rõ ràng.

Nên bổ sung:

- `bluez` và `bluez-utils`.
- Blueman hoặc UI Bluetooth tích hợp.
- Tự reconnect thiết bị quen thuộc.
- Hiển thị battery của thiết bị.
- Profile A2DP/HFP cho tai nghe.

#### 6. Desktop portals, WebRTC screen sharing và MIME integration

Để Chrome, Electron, file picker, screen sharing và ứng dụng Flatpak hoạt động ổn định trên Wayland, cần có portal phù hợp như `xdg-desktop-portal` kết hợp `xdg-desktop-portal-wlr` (hoặc GTK), cùng cấu hình MIME/default applications.

Nên bổ sung:

- Default browser, terminal, editor.
- File associations cho code, archive, image, video và PDF.
- Screen sharing portal cho Google Meet, Slack, Lark: Cấu hình cờ Chromium/Electron (`~/.config/chrome-flags.conf` hoặc environment) với `--enable-features=UseOzonePlatform,WebRTCPipeWireCapturer --ozone-platform=wayland`.
- Đảm bảo Fcitx5 gõ tiếng Việt ổn định trên Electron bằng `XMODIFIERS="@im=fcitx"` và `ELECTRON_OZONE_PLATFORM_HINT="auto"`.
- Open-with integration cho Yazi.

#### 7. Kanata — Keyboard remapping mức Kernel

Cần một trình ánh xạ phím phần cứng mạnh mẽ chạy ở tầng kernel qua `/dev/uinput`, không phụ thuộc vào desktop environment hay compositor:
- Home-row mods: Biến các phím `A`, `S`, `D`, `F` thành `Super`, `Alt`, `Ctrl`, `Shift` khi giữ đè; gõ bình thường khi bấm nhả nhanh.
- Dual-role phím CapsLock: Bấm nhả hoạt động như `Escape`, giữ đè hoạt động như `Control`.
- Layer navigation: Giữ Space để biến các phím `H/J/K/L` thành cụm mũi tên di chuyển, kèm `Home`, `End`, `PageUp`, `PageDown` ngay trên hàng phím cơ sở mà không cần nhấc tay.
- Triển khai: Cài `kanata-bin` (AUR), cấu hình udev rule cho nhóm `input`/`uinput`, chạy dưới dạng systemd user/system service.

#### 8. Warpd — Trải Checkpoint/Hint điều khiển chuột bằng bàn phím

Thao tác bàn phím tốc độ cao trên toàn màn hình Wayland mà không cần chạm tay vào chuột:
- **Hint Mode (`warpd --hint`)**: Trải một lưới các ký tự 2 chữ cái (checkpoints) phủ khắp màn hình. Người dùng chỉ cần gõ 2 ký tự tương ứng, con trỏ chuột sẽ lập tức nhảy đến vị trí đó và thực hiện click chuột trái/phải hoặc bắt đầu kéo thả.
- **Grid Mode & Normal Mode**: Điều khiển con trỏ mượt mà theo 4 hướng bằng các phím `H/J/K/L`, thu hẹp vùng chọn theo lưới 4 góc màn hình.
- **Hệ sinh thái Checkpoint đồng bộ**:
  - Toàn bộ desktop: `warpd` cho mọi cửa sổ ứng dụng và hệ thống.
  - Trình duyệt Chrome: Extension `Vimium C` trải hint chữ cái lên mọi link/button/input.
  - Editor Neovim: Plugin `flash.nvim` nhảy 2D trên code buffer bằng checkpoint ký tự tương tự.

---

### P1 — tăng mạnh năng suất phát triển

#### 9. Git identity, GPG/SSH signing, credential helper và local override

Vault có backup `.ssh`, `.gnupg` và `.config/gh`, nhưng hệ sinh thái dotfiles chưa quản lý cấu hình `.gitconfig` chuẩn.

Nên bổ sung:

- `modules/git` quản lý file `.gitconfig`:
  - Git Delta pager (đã có binary trong pacman).
  - Git credential helper dùng `git-credential-libsecret` liên kết với GNOME Keyring.
  - Commit signing tự động bằng SSH key hoặc GPG key (`commit.gpgsign = true`).
  - Phân tách email theo thư mục công việc và cá nhân bằng directive `[includeIf "gitdir:~/Workspaces/work/"]`.
- Cơ chế ghi đè cục bộ (Local Override):
  - Tự động nạp `~/.gitconfig.local` và `~/.zshrc.local` nếu tồn tại.
  - Đưa các file `.local` vào `.gitignore` của dotfiles để đảm bảo token cá nhân, cấu hình công ty không bao giờ bị commit nhầm lên remote repo.
- `ssh-agent` hoặc systemd user agent, `pinentry` phù hợp với Wayland, GitHub CLI (`gh`).

#### 10. `mise` — Quản lý Runtime đa ngôn ngữ hiện đại

Thay vì phải cài đặt và bảo trì phân mảnh nhiều version manager khác nhau như `nvm`, `pyenv`, `rustup`, `gvm`, `poetry`, khuyến nghị chuẩn hóa toàn bộ bằng `mise-en-place` (`mise`):
- Viết bằng Rust, tốc độ shim cực nhanh, không gây chậm trễ khi mở shell mới như NVM.
- Quản lý tập trung mọi runtime cần thiết: Node.js, Python, Rust, Go, Bun, Terraform/OpenTofu, AWS CLI, pnpm.
- Tự động nhận diện và switch version theo file cấu hình dự án: `.tool-versions`, `.mise.toml`, `package.json`, `.python-version`.
- Cấu hình kích hoạt đơn giản trong `.zshrc`: `eval "$(mise activate zsh)"`.

#### 11. Cloud Tooling: AWS & GCP Workflow

Người dùng thường xuyên làm việc với hạ tầng đám mây AWS và GCP, cần bổ sung các công cụ chuẩn hóa:
- **AWS**:
  - `aws-cli-v2` (hoặc `aws-cli-v2-bin`).
  - `granted` (cung cấp lệnh `assume`): Chuyển đổi giữa nhiều tài khoản/vai trò AWS SSO tức thì ngay trên terminal và mở session trình duyệt tách biệt qua Firefox/Chrome container.
  - `aws-session-manager-plugin`: Kết nối SSH trực tiếp vào EC2 thông qua AWS Systems Manager (SSM) mà không cần mở port 22 hoặc dựng Bastion host.
- **GCP**:
  - `google-cloud-cli` (`gcloud`).
  - `gke-gcloud-auth-plugin`: Plugin xác thực bắt buộc khi dùng `kubectl` kết nối tới các cụm Google Kubernetes Engine (GKE).
  - Cấu hình Application Default Credentials (ADC) phục vụ chạy và debug code local gọi Google Cloud APIs (`gcloud auth application-default login`).
- **Infrastructure as Code (IaC)**:
  - `opentofu` (hoặc `terraform`), kết hợp `terragrunt` để quản lý cấu hình hạ tầng đa môi trường.

#### 12. Database CLI & Remote Tunneling

Bên cạnh Beekeeper Studio (GUI), cần có công cụ dòng lệnh tốc độ cao để thao tác trực tiếp từ terminal hoặc viết script tự động:
- `usql`: Universal SQL CLI hỗ trợ PostgreSQL, MySQL, SQLite, Oracle, ClickHouse, SQL Server với tính năng auto-completion và syntax highlighting.
- `pgcli`: CLI chuyên biệt cho PostgreSQL với gợi ý cú pháp, tên bảng và schema thông minh.
- `iredis`: CLI cho Redis với auto-completion lệnh và key.
- Helper kết nối bảo mật: Tận dụng Tailscale hoặc script port-forwarding SSH tunnel (`ssh -L`) để kết nối an toàn từ máy cá nhân vào các RDS/Cloud SQL private instance.

#### 13. Tailscale và remote network mesh

Bổ sung Tailscale vào lớp remote access để máy cá nhân, VPS, laptop và điện thoại có địa chỉ ổn định trong tailnet. Nên cấu hình MagicDNS, hostname cố định, SSH qua Tailscale với ACL riêng, subnet route khi cần, exit node tùy chọn và helper kiểm tra node online, IP tailnet và latency. Tailscale nên là lớp private network chính; Cloudflare WARP tiếp tục dùng cho routing/DNS riêng, tránh bật hai lớp VPN cùng lúc nếu không cần.

#### 14. 9remote qua npm

Bổ sung `9remote` vào `packages/node.txt` hoặc một nhóm npm tool riêng. Workflow nên hỗ trợ kết nối tới host trong tailnet, chọn host bằng hostname, mở terminal, port forwarding, remote command, SSH agent và khởi động remote desktop hoặc Sunshine session. Có thể tạo các lệnh `remote <host>`, `remote-shell <host>` và `remote-forward <host> <port>` nếu 9remote cung cấp các lệnh tương ứng.

#### 15. Sunshine và remote desktop chuyên sâu cho lập trình

Đáp ứng nhu cầu remote vào desktop máy trạm để code từ xa (từ laptop, tablet) với độ trễ tối thiểu và trải nghiệm mượt mà như ngồi trước máy:
- **Host (Máy trạm)**:
  - Cài đặt `sunshine` chạy dưới dạng systemd user service, tận dụng GPU hardware encoder (NVENC hoặc VAAPI).
  - **Headless Virtual Display**: Thiết lập màn hình ảo (virtual output qua Wayland, `evdi` hoặc HDMI dummy plug) để máy trạm có thể stream ở độ phân giải cao và tần số quét cao (1080p/2K/4K 60-120Hz) ngay cả khi màn hình vật lý đang tắt hoặc không cắm cáp.
  - Ràng buộc Sunshine chỉ lắng nghe trên interface nội bộ của Tailscale, không mở port trực tiếp ra Internet.
  - Cấu hình audio PipeWire, microphone, clipboard hai chiều và hành vi khóa màn hình khi client disconnect.
- **Client (Thiết bị truy cập)**:
  - Cài đặt Moonlight (Moonlight-qt) trên máy client kết nối về Sunshine.
  - Bổ sung Wake-on-LAN (WOL) hoặc BIOS AC recovery để có thể bật/đánh thức máy trạm từ xa khi cần.
- **Lựa chọn Remote Coding gọn nhẹ**:
  - Hỗ trợ VS Code Remote Tunnels / Remote SSH qua Tailscale khi người dùng chỉ muốn code mà không cần stream toàn bộ giao diện desktop.

#### 16. Python, Rust, Go và container development

Hiện package list có compiler cơ bản nhưng chưa phải một developer workstation đầy đủ. Bổ sung:
- Python, pipx, uv.
- Rust toolchain: cargo, clippy, rustfmt, rust-analyzer.
- Go và các công cụ gopls, delve.
- Docker Compose plugin (`docker-compose`).
- Docker Buildx (`docker-buildx`).
- Hadolint, Dive, Trivy.
- Docker registry login helpers và script quản lý cleanup tài nguyên Docker.

#### 17. VS Code bản mới và editor ecosystem

Bổ sung VS Code bản mới theo một nguồn cài đặt ổn định, đồng thời giữ Antigravity IDE như editor chuyên biệt. Nên có `code` và `code-insiders` rõ ràng, profile work/personal/remote/minimal, Settings Sync, Remote SSH, Dev Containers, Remote Tunnels, extensions theo nhóm ngôn ngữ, terminal profile dùng Zsh/Zellij và theme, icon theme, font, keybinding đồng bộ với Noctalia.

#### 18. Theme system đồng bộ với Noctalia

Hiện theme nằm rải rác trong Kitty, Starship, Zellij, VS Code, Antigravity, Neovim và Chrome. Nên tạo một theme source duy nhất dựa trên palette của Noctalia, sau đó sinh hoặc liên kết cấu hình cho từng ứng dụng. Cần đồng bộ background, foreground, accent, error/warning/success/info, border, inactive pane, cursor, selection, Zellij bar, Kitty opacity, VS Code workbench, Neovim plugin UI, Chrome/Chromium, FZF, Yazi, bat và delta.

Nên có dark/light mode và một lệnh hoặc signal để đổi theme toàn bộ thay vì sửa từng file.

#### 19. Noctalia configuration layer

Bổ sung module cấu hình Noctalia riêng để quản lý bar/widget, launcher, notification center, power menu, wallpaper, lock screen, idle behavior, OSD volume/brightness, workspace indicator, network, Bluetooth, battery widget, theme/palette và hotkey đồng bộ với Umbriel. Umbriel nên chịu trách nhiệm window management, còn Noctalia chịu trách nhiệm shell UI và desktop controls.

#### 20. Neovim ecosystem

Neovim hiện mới được cài binary; nên bổ sung module cấu hình editor gồm init.lua, lazy.nvim, LSP (thông qua Mason), formatter, completion, Treesitter, Telescope/Snacks, Git integration, Yazi integration, diagnostics UI, which-key, session/project management, plugin `flash.nvim` để nhảy vị trí bằng checkpoint ký tự, và hỗ trợ cho Lua, Bash, Nix, JSON, TOML, YAML, TypeScript, Python, Rust, Go, Markdown.

Neovim nên dùng cùng font, cursor color, statusline color và semantic palette với Kitty và VS Code. Cần có keymap cho mở project, tìm file, grep repo, format buffer, xem diagnostics và mở terminal Zellij.

#### 21. SSH như chạy trên máy local

Bổ sung lớp remote filesystem và remote development gồm SSH ControlMaster/ControlPersist/keepalive, `sshfs` hoặc sshfs3, systemd user mount hoặc autofs, mosh, rsync, sftp/scp helper, port forwarding, Tailscale SSH, Remote SSH của VS Code và remote Neovim. Nên mount dưới `~/mnt/remote/<host>` và có các lệnh:

```text
ssh-mount <host> [path]
ssh-umount <host>
ssh-sync <host> <local> <remote>
ssh-forward <host> <local-port> <remote-port>
ssh-project <host> <path>
```

Dùng SSHFS cho file nhỏ và browsing, rsync cho project lớn, còn code execution nên chạy qua VS Code Remote SSH hoặc Neovim remote để tránh latency khi build trên filesystem mount.

---

### P2 — hoàn thiện desktop experience

#### 22. Launcher và application runner

Noctalia đã có launcher binding, nhưng chưa thấy một lớp fallback hoặc workflow thống nhất. Có thể dùng Walker, Wofi, Rofi-Wayland hoặc launcher native của desktop environment.

Feature nên có:

- Mở app.
- Tìm file.
- Tính toán.
- SSH host picker.
- Recent files.
- Clipboard history (tích hợp `cliphist`).
- Power actions.
- Window switcher.

#### 23. Wallpaper, lock screen và idle manager

Greeter chỉ giải quyết login. Một desktop hoàn chỉnh cần thêm:

- Wallpaper daemon.
- Idle timeout.
- Auto lock.
- Suspend/hibernate.
- DPMS off.
- Lock trước suspend.
- Khóa khi đóng nắp laptop.

#### 24. Audio control và media keys

PipeWire đã có, nhưng nên thêm `pavucontrol` hoặc `pwvucontrol`, `playerctl`, volume OSD và media key bindings.

Nên hỗ trợ:

- Chuyển output nhanh.
- Chuyển microphone.
- Mute từng app.
- Hiển thị volume trên notification bar.
- Play/pause/next/previous.

#### 25. File manager integration

Yazi đã được cấu hình, nhưng nên hoàn thiện ecosystem:

- Preview image/video/PDF.
- Archive create/extract.
- Mount/unmount removable drive.
- SFTP/SSH browsing.
- Trash integration.
- Open-with theo MIME.
- Thumbnail cache.

#### 26. PDF, image và media tools

Nếu đây là workstation phát triển và sử dụng cá nhân hằng ngày, nên cân nhắc:

- Zathura hoặc sioyek cho PDF.
- ImageMagick hoặc `chafa` cho terminal preview.
- ffmpeg.
- mpv.
- yt-dlp.
- `imv` hoặc trình xem ảnh Wayland.
- OBS nếu thường xuyên recording.

#### 27. Removable media và file transfer

Có thể bổ sung:

- Udisks2.
- udiskie.
- gvfs backend.
- Android file transfer/MTP.
- `rsync` workflow cho ổ ngoài.
- Mount notification.

---

### P3 — networking và remote workflow

#### 28. DNS, VPN và remote access

NetworkManager và Cloudflare WARP chưa tạo thành một remote networking ecosystem hoàn chỉnh. Có thể thêm:

- WireGuard tools.
- Tailscale hoặc Headscale client.
- `networkmanager-openvpn` nếu cần.
- `resolvectl`/systemd-resolved workflow.
- DNS profile theo mạng.
- mtr, nmap, tcpdump, socat và netcat.

#### 29. Firewall và network visibility

Nếu thường chạy Docker, 9router hoặc service local, nên có:

- UFW hoặc firewalld.
- Port listing helper tốt hơn `ss` alias hiện tại.
- Network namespace/debug helper.
- DNS lookup helper.
- HTTP/TLS diagnostics bằng curl, openssl và HTTPie.

#### 30. Sync và backup dữ liệu cá nhân (Áp dụng YAGNI)

Thay vì dựng các hệ thống backup phức tạp như Borgmatic hoặc Rclone cồng kềnh, khuyến nghị tối giản theo nhu cầu thực tế:
- **Dotfiles & Code**: Đẩy lên GitHub private repositories.
- **Secrets & Credentials**: Tận dụng module `modules/vault` (Age encryption) đã có sẵn trong repo.
- **Ghi chú cá nhân (Obsidian)**: Đồng bộ qua Git plugin hoặc Syncthing giữa các máy cá nhân.
- Tách rõ ranh giới: Dotfiles, Secrets, Project source, Documents, Media, Browser/application profiles.

---

### P4 — tiện ích vận hành hằng ngày

#### 31. System health và cleanup

Nên có helper cho:

- Disk usage.
- Journal size.
- Failed systemd services.
- Pacman cache cleanup.
- Docker image/container cleanup (`docker system prune`).
- Orphan package cleanup.
- Memory pressure.
- Battery health.
- Temperature.

#### 32. Calendar, reminders và notes

Nếu dùng máy như workstation cá nhân, có thể bổ sung:

- `khal`/`vdirsyncer` cho calendar.
- `taskwarrior` hoặc `todo.txt` cho task.
- Obsidian CLI/workflow vì Obsidian đã được cài.
- Quick capture từ launcher.
- Search notes bằng ripgrep hoặc fzf.

#### 33. Browser ecosystem

Chrome đã có flag libsecret, nhưng nên hoàn thiện:

- Policy/profile separation.
- Browser launch profiles (`chrome-work`, `chrome-personal`, `chrome-proxy`).
- Cấu hình extension `Vimium C` để duyệt web nhanh không cần chuột.
- Temporary clean profile.
- Default download directory.
- Browser extension inventory.
- PWA launcher.
- Proxy profile cho 9router/WARP.

---

## Danh sách package có khả năng nên thêm

Đây là danh sách gợi ý để chọn lọc, không nên cài toàn bộ một cách máy móc:

```text
# Desktop / Wayland / Checkpoint Navigation
xdg-desktop-portal
xdg-desktop-portal-wlr
xdg-desktop-portal-gtk
mako hoặc swaync
grim
slurp
swappy
wl-screenrec
cliphist
brightnessctl
playerctl
pavucontrol
kanata-bin (AUR)
warpd (AUR)

# Hardware / connectivity
bluez
bluez-utils
blueman
power-profiles-daemon hoặc tlp
thermald
udiskie

# Developer workflow / Runtime / Multi-language
mise
docker-compose
docker-buildx
git-delta

# Cloud & DB CLI
aws-cli-v2
granted-bin (AUR)
google-cloud-cli (AUR/Pacman)
gke-gcloud-auth-plugin (AUR)
opentofu
usql-bin (AUR)
pgcli
iredis

# Remote Desktop & Connectivity
tailscale
sunshine (AUR)
moonlight-qt

# Credentials / security
keepassxc
gnupg
pinentry
keychain

# AI / media / network
ollama
ffmpeg
mpv
yt-dlp
wireguard-tools
mtr
nmap
httpie
```

---

## Thứ tự nên triển khai

Nếu ưu tiên hiệu quả sử dụng hằng ngày và tốc độ công việc, thứ tự hợp lý là:

1. Kanata keyboard remapping và Warpd checkpoint hint navigation.
2. Clipboard history (`cliphist`) và Screenshot/annotation (`grim`, `slurp`, `swappy`).
3. Notification center và WebRTC Screen-sharing portal (`xdg-desktop-portal-wlr`, chrome-flags).
4. Git module (`.gitconfig`, signing, credential helper, local override hook).
5. `mise` runtime manager thay thế nvm và cấu hình multi-runtime (Node, Python, Rust, Go).
6. Cloud CLI (AWS, GCP, OpenTofu) và Database CLI (`usql`, `pgcli`, `iredis`).
7. Tailscale và remote access nền tảng.
8. Sunshine remote desktop (headless virtual display) và Moonlight client.
9. Bluetooth và power management.
10. Neovim ecosystem module và VS Code Remote SSH.
11. Theme/Noctalia synchronization.
12. Media, PDF và removable-drive workflow.

---

## Kết luận

Bộ dotfiles hiện đã có phần lõi terminal, compositor, input method, Node, Docker, AI gateway và các ứng dụng desktop. Những khoảng trống lớn nhất không nằm ở thêm alias hay thêm một ứng dụng riêng lẻ, mà nằm ở các lớp kết nối giữa chúng:

- Clipboard và notification chưa hoàn chỉnh.
- Wayland desktop integration chưa đủ (thiếu portal WebRTC screen share cho Slack/Lark).
- Thao tác bàn phím chưa đạt tốc độ cao nhất (thiếu Kanata remapping kernel và Warpd hint navigation).
- Developer identity và local override chưa được quản lý bằng Git module chuẩn.
- Runtime còn phân mảnh, cần chuyển sang `mise` để hợp nhất.
- Thiếu lớp công cụ CLI cho Cloud (AWS, GCP) và Database (Postgres, Redis).
- Laptop hardware/power/Bluetooth chưa được bao phủ.
- Noctalia mới được dùng qua vài keybind, chưa có desktop shell configuration layer đầy đủ.
- Theme đang phân tán giữa compositor, terminal, editor và browser.
- Neovim chưa có ecosystem cấu hình trong repo.
- Remote workflow chưa có Tailscale, 9remote, SSHFS và Sunshine remote desktop (headless display) tích hợp.
- Vault chưa thay thế cho backup/sync dữ liệu cá nhân.

Nếu chỉ chọn một gói nâng cấp thực dụng, nên triển khai theo thứ tự: **Kanata + Warpd + Clipboard/Screenshot**, **Git identity + mise**, **Cloud/DB CLI**, **SSHFS + Tailscale**, **Sunshine headless remote desktop**, rồi **Neovim ecosystem**. Đây là chuỗi feature tạo ra cảm giác một workstation thống nhất dù đang dùng local, remote shell hay remote desktop.

---

## Lộ trình triển khai thực tế

Phần này chuyển audit thành các thay đổi có thể thực hiện trực tiếp trong repository, theo đúng hệ sinh thái đã chọn.

### Giai đoạn 1 — Bàn phím, Checkpoint navigation và Desktop Wayland

1. Tạo module `modules/kanata/` với file cấu hình `kanata.kbd` (home-row mods, dual-role CapsLock thành Esc/Ctrl, layer navigation) và service systemd.
2. Cài đặt `warpd`, gán phím tắt gọi Hint Mode (`Mod+H` hoặc `Mod+Shift+Space`) trong `modules/umbriel/files/keybinds.toml`.
3. Thêm `cliphist`, `grim`, `slurp`, `swappy`, `xdg-desktop-portal-wlr` vào danh sách package.
4. Cấu hình phím tắt chụp màn hình, ghi chú ảnh và mở lịch sử clipboard trong Umbriel.
5. Thêm cấu hình flag WebRTC PipeWire vào file wrapper hoặc `~/.config/chrome-flags.conf` để hỗ trợ screen sharing trong Slack, Lark, Chrome.

### Giai đoạn 2 — Git Identity, `mise` Runtime, Cloud và Database Tools

1. Tạo module `modules/git/` quản lý `.gitconfig` chuẩn (Delta pager, `git-credential-libsecret` với GNOME Keyring, commit signing, `includeIf` work/personal).
2. Thêm hook tự động nạp `~/.gitconfig.local` và `~/.zshrc.local` (nằm trong `.gitignore`).
3. Thêm `mise` vào package list, thay thế NVM trong `.zshrc` bằng `eval "$(mise activate zsh)"`.
4. Cài đặt các công cụ Cloud (`aws-cli-v2`, `granted-bin`, `google-cloud-cli`, `gke-gcloud-auth-plugin`, `opentofu`) và DB CLI (`usql-bin`, `pgcli`, `iredis`).

### Giai đoạn 3 — Remote Access và Remote Desktop Headless

1. Thêm Tailscale vào nhóm package hệ thống và tạo module `modules/tailscale/setup.sh`.
2. Tạo cấu hình SSH dùng hostname MagicDNS, `ControlMaster`, `ControlPersist`, keepalive và alias theo host.
3. Tạo module SSHFS với thư mục mount chuẩn `~/mnt/remote/<host>` và user systemd mount/automount.
4. Thêm helper `ssh-mount`, `ssh-umount`, `ssh-sync`, `ssh-forward` và `ssh-project`.
5. Tạo module Sunshine cho máy trạm chạy stream desktop: Cấu hình systemd user service, hardware encoder (NVENC/VAAPI), headless virtual display (để stream khi tắt màn hình) và chỉ lắng nghe qua Tailscale IP.
6. Cài đặt Moonlight trên client tương ứng.

### Giai đoạn 4 — Editor, Neovim và Theme System

1. Thêm VS Code bản mới vào đúng nguồn package đã chọn, giữ Antigravity độc lập.
2. Tạo profile VS Code cho local, remote SSH và container.
3. Tạo module Neovim riêng với lazy.nvim, Mason (LSP, formatters, linters), Treesitter, Telescope/Snacks, Git integration và plugin `flash.nvim` (tương đồng với Warpd).
4. Tạo `modules/noctalia/` quản lý bar, launcher, notification center, wallpaper, lock, power, OSD và widgets.
5. Tạo một palette canonical của Noctalia với dark/light variant, đồng bộ sang Kitty, Zellij, Neovim, VS Code, Delta.
6. Đồng bộ hotkey giữa Umbriel và Noctalia để không có shortcut trùng hoặc khác hành vi.

### Các điểm cần xác nhận trước khi triển khai package

- Package VS Code: dùng `visual-studio-code-bin`, `code`, hay một nguồn khác.
- 9remote: xác nhận tên npm package, binary command và cơ chế authentication.
- Sunshine: xác nhận GPU encoder (Nvidia hay Intel/AMD) và cơ chế virtual display (HDMI dummy plug hay virtual driver `evdi`/headless Wayland output).
- Moonlight: xác định chỉ cài trên client hay cũng quản lý trong dotfiles này.
- Tailscale: xác định máy này là client, exit node, subnet router hay SSH server.
- SSHFS: xác định các host/path mặc định và có cần automount hay chỉ mount thủ công.
- Kanata: xác nhận layout bàn phím vật lý (ANSI hay ISO) và danh sách thiết bị bàn phím trong `/dev/input/by-id/`.
