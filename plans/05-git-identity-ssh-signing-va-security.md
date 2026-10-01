# Kế hoạch 05: Quản lý Định danh Git, Ký Commit SSH `ed25519` và Bảo mật Repo

## 1. Tên chức năng
**Hoàn Thiện Module Git Chuẩn Hóa: Định Danh Đa Hồ Sơ, Ký Commit Tự Động Bằng Khóa SSH `ed25519`, GNOME Keyring Credential Helper và Ngăn Chặn Lộ Secret Với `gitleaks`.**

---

## 2. Mô tả chức năng

### 2.1. Vấn đề hiện tại
* Thư mục `modules/git` trong repo dotfiles hiện tại mới chỉ là **thư mục rỗng**, chưa có bất kỳ file cấu hình nào.
* Chưa có file `.gitconfig` toàn cục chuẩn: thiếu cấu hình tích hợp Git Delta pager, chưa lưu credentials an toàn vào GNOME Keyring (dẫn đến việc phải nhập token thường xuyên).
* Commit chưa được xác thực (chưa có nhãn "Verified" trên GitHub) do thiếu cấu hình SSH/GPG commit signing.
* Không phân biệt được email cá nhân và email công ty: dễ xảy ra tình trạng commit nhầm email cá nhân vào dự án công ty hoặc ngược lại.
* Chưa có cơ chế nạp file ghi đè cục bộ (`~/.gitconfig.local`, `~/.zshrc.local`) để lưu trữ token riêng tư của từng máy mà không làm bẩn git status.
* Thiếu hàng rào tự động quét và chặn commit nhầm secret, API key hay private key lên GitHub.

### 2.2. Mục tiêu kỹ thuật
1. Xây dựng hoàn chỉnh module `modules/git/`:
   * Quản lý file `~/.gitconfig` toàn cục kế thừa Delta pager (`delta --dark --line-numbers`).
   * Sử dụng `git-credential-libsecret` để lưu trữ mật khẩu/PAT (Personal Access Token) tự động vào GNOME Keyring của desktop.
   * Tự động ký xác thực commit bằng khóa SSH `ed25519` (`gpg.format = ssh`, `commit.gpgsign = true`), hiện đại và dễ cấu hình hơn nhiều so với GPG truyền thống.
   * Cấu hình phân tách hồ sơ tự động thông qua directive `[includeIf "gitdir:~/Workspaces/work/"]`.
2. Tạo cơ chế Local Override an toàn:
   * Tự động nạp file `~/.gitconfig.local` (nếu tồn tại) ở cuối `.gitconfig`.
   * Khai báo các file `.local` vào `.gitignore` của dotfiles.
3. Thiết lập bảo mật tự động:
   * Cài đặt `gitleaks` và tạo pre-commit hook tự động quét mã nguồn trước mỗi lần commit.
   * Cấu hình `pinentry-gnome3` cho Wayland để hộp thoại nhập passphrase không bị treo.

---

## 3. Chi tiết triển khai

### 3.1. Các file cần tạo và sửa đổi

* **[MODIFY]** [packages/pacman.txt](file:///home/loc/Workspaces/dotfiles/packages/pacman.txt): Bổ sung `gitleaks` và `pinentry`.
* **[NEW]** `modules/git/files/.gitconfig`: File cấu hình Git toàn cục.
* **[NEW]** `modules/git/files/.gitconfig-work`: Cấu hình ghi đè email/name cho thư mục công việc.
* **[NEW]** `modules/git/setup.sh`: Script symlink cấu hình, kiểm tra khóa SSH và cài pre-commit hook.
* **[MODIFY]** [.gitignore](file:///home/loc/Workspaces/dotfiles/.gitignore): Đảm bảo bỏ qua các file `*.local`.
* **[MODIFY]** [install.sh](file:///home/loc/Workspaces/dotfiles/install.sh): Thêm lệnh thực thi `modules/git/setup.sh`.

### 3.2. Cấu hình chi tiết `modules/git/files/.gitconfig`

```ini
[user]
    name = Loc Bui
    email = locbh3010@gmail.com
    signingkey = ~/.ssh/id_ed25519.pub

[core]
    editor = nvim
    pager = delta
    autocrlf = input
    quotepath = false

[credential]
    helper = /usr/lib/git-core/git-credential-libsecret

[gpg]
    format = ssh

[commit]
    gpgsign = true

[tag]
    gpgsign = true

[init]
    defaultBranch = main

[interactive]
    diffFilter = delta --color-only

[delta]
    navigate = true
    light = false
    line-numbers = true
    side-by-side = false
    syntax-theme = Dracula

[merge]
    conflictstyle = diff3

[diff]
    colorMoved = default

# Tự động nạp cấu hình công ty khi clone code trong ~/Workspaces/work/
[includeIf "gitdir:~/Workspaces/work/"]
    path = ~/.gitconfig-work

# Nạp cấu hình riêng của từng máy (nếu có)
[include]
    path = ~/.gitconfig.local
```

#### File `modules/git/files/.gitconfig-work`
```ini
[user]
    name = Loc Bui (Work)
    email = loc.bui@company.com
    signingkey = ~/.ssh/id_work_ed25519.pub
```

---

## 4. Hướng dẫn sử dụng

### 4.1. Ký Commit bằng SSH Key trên GitHub
1. Thêm public key vào GitHub: Truy cập **GitHub Settings -> SSH and GPG keys -> New SSH Key**.
2. Chọn **Key type** là **Signing Key** (không phải Authentication Key) và dán nội dung file `~/.ssh/id_ed25519.pub`.
3. Khi thực hiện commit code:
   ```bash
   git commit -m "feat: implement feature"
   ```
4. Commit đẩy lên GitHub sẽ lập tức có tích xanh **Verified**.

### 4.2. Phân tách tự động môi trường Làm việc và Cá nhân
* Khi làm việc trong các thư mục dự án cá nhân (mặc định): Git dùng email `locbh3010@gmail.com`.
* Khi tạo hoặc clone dự án vào thư mục `~/Workspaces/work/`: Git tự động chuyển sang email `loc.bui@company.com` và khóa ký tương ứng mà không cần phải chạy `git config user.email` thủ công.

### 4.3. Quét Secret tự động với Gitleaks
* Nếu bạn vô tình dán một AWS Secret Access Key, Private Key hoặc Database Password vào mã nguồn và gõ `git commit`, `gitleaks` sẽ lập tức phát hiện, hủy lệnh commit và in ra chi tiết dòng bị lộ:
  ```text
  ○ Error: leaks found: 1
  ○ Rule: aws-secret-access-key
  ○ Commit blocked by gitleaks pre-commit hook!
  ```

---

## 5. Tiêu chuẩn kiểm thử & Nghiệm thu (Verification)

1. **Kiểm tra Commit Signing:**
   ```bash
   git commit --allow-empty -m "test: test commit signing"
   git log -1 --show-signature
   # Phải hiển thị: "Good "git" signature for ... with ED25519 key"
   ```
2. **Kiểm tra Credential Helper:**
   * Clone một private repo: Thông tin xác thực phải được lưu tự động trong GNOME Keyring (kiểm tra bằng ứng dụng Seahorse).
3. **Kiểm tra Gitleaks:**
   ```bash
   gitleaks detect --source . -v
   # Kiểm tra không có secret nào bị lọt vào lịch sử git
   ```
