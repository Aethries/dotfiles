# Hardware Specification & `.machine/` Isolation

Tài liệu này hướng dẫn cách cấu hình phần cứng nội bộ của từng máy vật lý trong thư mục `.machine/`, tuân thủ nguyên tắc không bao giờ commit thông tin phần cứng cá nhân vào git.

---

## 1. Vai trò của `.machine/`

Thư mục `.machine/` nằm ở thư mục gốc của repository và được cấu hình trong `.gitignore`:
- **Mục đích:** Lưu trữ toàn bộ trạng thái định danh vật lý, phần cứng, tài khoản cá nhân, và các module phần cứng tùy chọn (opt-in).
- **Quy tắc:** Tuyệt đối không commit bất kỳ file nào trong `.machine/` vào repository git.

---

## 2. Cấu trúc thư mục `.machine/`

```text
.machine/
├── configuration.nix           # Entrypoint cấu hình máy cục bộ (nixos-rebuild import)
├── hardware-configuration.nix  # File sinh tự động từ nixos-generate-config
├── hardware-extra.nix          # Khai báo driver GPU, kernel params, udev rules riêng
└── identity.nix                # Định danh máy: hostname, primary user, stateVersion
```

---

## 3. Chi tiết các file cấu hình

### 3.1. `identity.nix`
Chứa thông tin định danh và tài khoản máy:
```nix
{ ... }:
{
  networking.hostName = "nixos-workstation";
  system.stateVersion = "26.05"; # Giữ nguyên phiên bản khởi tạo ban đầu của máy này

  users.users."myuser" = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "input"
      "uinput"
      "docker"
      "seat"
      "video"
    ];
  };

  # Khai báo user chính cho Desktop Greeter (tự động đồng bộ không cần gõ mật khẩu nếu cấu hình)
  # dotfiles.primaryUser = "myuser";
}
```

### 3.2. `hardware-extra.nix`
Nạp các module phần cứng dùng chung từ `modules/hardware/` theo hình thức opt-in:

#### Ví dụ máy dùng Intel GPU:
```nix
{ ... }:
{
  imports = [
    ../modules/hardware/intel-graphics.nix
  ];

  # Tham số kernel riêng (nếu cần cho máy này)
  boot.kernelParams = [
    # "usbcore.autosuspend=-1"
  ];
}
```

#### Ví dụ máy sử dụng bàn phím WEIKAV NUT75:
```nix
{ ... }:
{
  imports = [
    ../modules/hardware/weikav-nut75.nix
  ];
}
```

### 3.3. `configuration.nix`
Cầu nối tổng hợp giữa repository và máy cục bộ:
```nix
{ ... }:
{
  imports = [
    ../configuration.nix
    ./hardware-configuration.nix
    ./hardware-extra.nix
    ./identity.nix
  ];

  # Cấu hình Bootloader riêng của máy (UEFI hoặc BIOS)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
```

---

## 4. Tự động sinh trạng thái (Bootstrap & Installer)

Khi chạy `./scripts/bootstrap.sh` hoặc `./scripts/nixos-installer.sh`:
1. Script kiểm tra sự tồn tại của `.machine/`.
2. Nếu chưa có, script tự động sinh `hardware-configuration.nix` (thông qua `nixos-generate-config`).
3. Tự động lấy username và hostname hiện tại để điền vào `identity.nix`.
4. Phát hiện GPU để tạo `hardware-extra.nix` phù hợp.
5. Tạo `configuration.nix` liên kết toàn bộ cấu hình.
