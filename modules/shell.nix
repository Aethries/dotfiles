{ pkgs, ... }:

{
  # Kích hoạt Zsh trên toàn hệ thống
  programs.zsh = {
    enable = true;
    enableCompletion = false; # Zimfw tự quản lý compinit và cache completion hiệu quả hơn
  };

  # Giữ cấu hình Bash dự phòng
  programs.bash = {
    completion.enable = true;
  };

  # Đặt Zsh làm shell mặc định cho user
  users.defaultUserShell = pkgs.zsh;

  # ----------------------------------------------------------
  # Direnv & Nix-Direnv (Tự động nạp môi trường lập trình theo từng dự án)
  # ----------------------------------------------------------
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
