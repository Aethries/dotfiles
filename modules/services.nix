{ pkgs, ... }:

{
  # ============================================================
  # System Services, Hardware & Daemons
  # ============================================================

  # ----------------------------------------------------------
  # Container Runtime (Docker)
  # ----------------------------------------------------------
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # ----------------------------------------------------------
  # Bluetooth & Hardware Peripherals
  # ----------------------------------------------------------
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  # ----------------------------------------------------------
  # Seat Management (seatd) & Hardware Permissions
  # ----------------------------------------------------------
  # Bàn phím WEIKAV NUT75 có chuỗi UNIQ/serial chứa ký tự điều khiển (0x0c / form feed).
  # systemd 259.4+/260 kiểm tra thuộc tính thất bại (Refusing invalid property: UNIQ),
  # khiến systemd-logind từ chối bàn giao thiết bị cho Wayland compositors (TakeDevice trả về ENODEV).
  # Sử dụng seatd làm seat manager cho libseat thay cho logind để compositor trực tiếp nhận bàn phím.
  services.seatd = {
    enable = true;
    group = "seat";
  };

  environment.sessionVariables = {
    LIBSEAT_BACKEND = "seatd";
  };

  users.users.greeter.extraGroups = [
    "seat"
    "input"
    "video"
  ];

  users.users.loc.extraGroups = [
    "seat"
    "input"
    "video"
  ];

  # ----------------------------------------------------------
  # Udev Rules & Hardware Quirks
  # ----------------------------------------------------------
  # Bàn phím WEIKAV NUT75:
  # - Dongle 2.4G không dây: 0c45:fef9
  # - Cáp cắm dây trực tiếp: 0c45:880c
  # Cấp quyền cho group input và đánh dấu đầy đủ seat/seat0/uaccess
  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="input", ATTRS{idVendor}=="0c45", ATTRS{idProduct}=="fef9|880c", ENV{ID_INPUT_KEY}="1", ENV{ID_INPUT_KEYBOARD}="1"
    ACTION=="add|change", SUBSYSTEM=="input", KERNEL=="event*", ATTRS{idVendor}=="0c45", ATTRS{idProduct}=="fef9|880c", TAG+="seat", TAG+="seat0", TAG+="uaccess", MODE="0660", GROUP="input"
  '';


  # ----------------------------------------------------------
  # Phone Connect (KDE Connect)
  # Enables device pairing, notification sync, shared clipboard,
  # wireless file transfer, and remote multimedia control.
  # Automatically manages DBus and opens firewall ports (TCP/UDP 1714:1764).
  # ----------------------------------------------------------
  programs.kdeconnect.enable = true;

  # ----------------------------------------------------------
  # Audio Server (PipeWire & WirePlumber)
  # Provides low-latency audio, ALSA/PulseAudio emulation and wpctl
  # ----------------------------------------------------------
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # ----------------------------------------------------------
  # Battery & Power Management (UPower)
  # Supplies battery status and power profiles to Noctalia bar
  # ----------------------------------------------------------
  services.upower.enable = true;

  # ----------------------------------------------------------
  # Removable Storage & Automount (udisks2 & gvfs)
  # Mount USB drives seamlessly in userspace without sudo
  # ----------------------------------------------------------
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  # ----------------------------------------------------------
  # Cloudflare WARP (warp-cli & warp-svc daemon)
  # ----------------------------------------------------------
  services.cloudflare-warp.enable = true; # Lần đầu dùng: 1111 register && 1111 connect

  # ----------------------------------------------------------
  # 9router DNS Routing (MITM Proxy)
  # Add 9router-managed hostnames here so they survive nixos-rebuild.
  # DO NOT manually edit /etc/hosts — it is a read-only Nix store symlink
  # that gets reset on every rebuild. Use networking.extraHosts instead.
  # The actual entries are also synced at runtime via init-9router.sh.
  # ----------------------------------------------------------
  networking.extraHosts = ''
    127.0.0.1 daily-cloudcode-pa.googleapis.com
    127.0.0.1 cloudcode-pa.googleapis.com
  '';
}
