{
  pkgs,
  lib,
  config,
  ...
}@args:

let
  inputs = args.inputs or null;
  lock = builtins.fromJSON (builtins.readFile ../flake.lock);
  getLockedFlake =
    name:
    let
      node = lock.nodes.${name}.locked;
    in
    builtins.getFlake "github:${node.owner}/${node.repo}/${node.rev}";

  noctaliaFlake =
    if (inputs != null && inputs ? noctalia) then inputs.noctalia else getLockedFlake "noctalia";

  noctaliaGreeterFlake =
    if (inputs != null && inputs ? noctalia-greeter) then
      inputs.noctalia-greeter
    else
      getLockedFlake "noctalia-greeter";

  normalUsers = builtins.attrNames (lib.filterAttrs (_: u: u.isNormalUser) config.users.users);

in
{
  imports = [
    noctaliaFlake.nixosModules.default
    noctaliaGreeterFlake.nixosModules.default
  ];

  # Window Manager (Niri)
  programs.niri.enable = true;

  # Noctalia Desktop Shell
  programs.noctalia = {
    enable = true;
    recommendedServices.enable = true;
  };

  # GPU Screen Recorder (cho Noctalia screen_recorder plugin)
  programs.gpu-screen-recorder.enable = true;

  # ⚠️  Intel-specific — override in .machine/configuration.nix for AMD/NVIDIA
  # Hardware Video Acceleration & Graphics (Intel VA-API / QSV)
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      vpl-gpu-rt
    ];
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
  };

  # Display Manager: Greetd with Noctalia Greeter (tự động đồng bộ theme, wallpaper với Noctalia Shell)
  programs.noctalia-greeter = {
    enable = true;
    # Tự động cấp quyền sync giao diện cho tất cả user thông thường mà không cần gõ mật khẩu root
    passwordless-sync-users = if normalUsers != [ ] then [ (builtins.head normalUsers) ] else [ ];
    settings = {
      session = {
        default = "Niri";
      };
      # Giao diện "Synced" để Noctalia Shell tự động đồng bộ hình nền, bảng màu, font chữ
      appearance = {
        scheme = "Synced";
        password_style = "random";
      };
      cursor = {
        theme = "Bibata-Modern-Ice";
        size = 24;
      };
      keyboard = {
        layout = config.services.xserver.xkb.layout or "us";
        numlock = true;
      };
    };
  };

  # ----------------------------------------------------------
  # GNOME Keyring & Secret Service (cho VS Code, Chrome, Git)
  # ----------------------------------------------------------
  services.gnome.gnome-keyring.enable = true;

  # Tự động mở khóa keyring khi đăng nhập qua greetd / console login
  security.pam.services.greetd.enableGnomeKeyring = true;
  security.pam.services.login.enableGnomeKeyring = true;

  # ----------------------------------------------------------
  # XDG MIME Default Applications (Web, URL Handlers, Apps)
  # ----------------------------------------------------------
  xdg.mime = {
    enable = true;
    defaultApplications = {
      # Web & Internet
      "text/html" = [
        "google-chrome.desktop"
      ];
      "x-scheme-handler/http" = [
        "google-chrome.desktop"
      ];
      "x-scheme-handler/https" = [
        "google-chrome.desktop"
      ];
      "x-scheme-handler/about" = [
        "google-chrome.desktop"
      ];
      "x-scheme-handler/unknown" = [
        "google-chrome.desktop"
      ];

      # PDF Documents
      "application/pdf" = [
        "google-chrome.desktop"
      ];

      # Communication & Workspace (Lark, Telegram, Slack, Jira)
      "x-scheme-handler/lark" = [ "bytedance-lark.desktop" ];
      "x-scheme-handler/feishu" = [ "bytedance-lark.desktop" ];
      "x-scheme-handler/feishu-open" = [ "bytedance-lark.desktop" ];
      "x-scheme-handler/tg" = [ "org.telegram.desktop.desktop" ];
      "x-scheme-handler/slack" = [ "slack.desktop" ];
      "x-scheme-handler/jira" = [ "jira.desktop" ];

      # IDE & AI Developer Tools
      "x-scheme-handler/antigravity" = [
        "antigravity-ide-url-handler.desktop"
        "antigravity-ide.desktop"
      ];
      "x-scheme-handler/antigravity-ide" = [
        "antigravity-ide-url-handler.desktop"
        "antigravity-ide.desktop"
      ];
      "x-scheme-handler/codex" = [
        "codex-desktop.desktop"
        "chatgpt.desktop"
      ];
    };
  };
}
