{ pkgs, ... }:

{
  time.timeZone = "Asia/Ho_Chi_Minh";

  i18n.defaultLocale = "en_US.UTF-8";

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Kích hoạt module uinput trong kernel & cấp quyền truy cập /dev/uinput
  # (cần thiết cho cơ chế giả lập phím uinput / non-preedit)
  hardware.uinput.enable = true;

  # Cấu hình bộ gõ tiếng Việt Fcitx5
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        fcitx5-bamboo # Bộ gõ tiếng Việt Bamboo
        fcitx5-gtk # Hỗ trợ ứng dụng GTK
        kdePackages.fcitx5-qt # Hỗ trợ ứng dụng Qt (Telegram Desktop...)
        kdePackages.fcitx5-configtool # Giao diện đồ họa cấu hình Fcitx5
      ];
    };
  };

  # Hỗ trợ bộ gõ và hiển thị cho các ứng dụng Wayland/Ozone (Chrome, Electron, Zed...)
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };
}
