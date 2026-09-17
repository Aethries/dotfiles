{ pkgs, ... }:

let
  # Pin plugin binaries instead of making every Zellij session download
  # mutable "latest" URLs at runtime.
  zjstatus = pkgs.fetchurl {
    url = "https://github.com/dj95/zjstatus/releases/download/v0.24.0/zjstatus.wasm";
    hash = "sha256-HM7ezh3tYs8+IJvmkM3TnKb7noIo7XGpUfZQf5lWZps=";
  };
  # Uses patched binary incorporating PR #35 (guards against duplicate
  # actions from orphaned plugin instances after client detach).
  vim-zellij-navigator = ../resources/zellij/plugins/vim-zellij-navigator.wasm;
  monocle = pkgs.fetchurl {
    url = "https://github.com/imsnif/monocle/releases/download/v0.100.2/monocle.wasm";
    hash = "sha256-TLfizJEtl1tOdVyT5E5/DeYu+SQKCaibc1SQz0cTeSw=";
  };
  room = pkgs.fetchurl {
    url = "https://github.com/rvcas/room/releases/download/v1.2.1/room.wasm";
    hash = "sha256-kLSDpAt2JGj7dYYhYFh6BfvtzVwTrcs+0jHwG/nActE=";
  };
  zellij-forgot = pkgs.fetchurl {
    url = "https://github.com/karimould/zellij-forgot/releases/download/0.4.2/zellij_forgot.wasm";
    hash = "sha256-MRlBRVGdvcEoaFtFb5cDdDePoZ/J2nQvvkoyG6zkSds=";
  };
in

{
  # ============================================================
  # Zellij Terminal Multiplexer Module
  # Modern workspace manager alternative to tmux
  # ============================================================
  environment.systemPackages = with pkgs; [
    zellij
  ];

  environment.etc."zellij/plugins/zjstatus.wasm".source = zjstatus;
  environment.etc."zellij/plugins/vim-zellij-navigator.wasm".source = vim-zellij-navigator;
  environment.etc."zellij/plugins/monocle.wasm".source = monocle;
  environment.etc."zellij/plugins/room.wasm".source = room;
  environment.etc."zellij/plugins/zellij-forgot.wasm".source = zellij-forgot;
}
