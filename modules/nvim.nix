{ pkgs, ... }:

{
  # ============================================================
  # Neovim Editor Module
  # High-performance, clean baseline editor configuration
  # ============================================================

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  # Build tools required for compiling plugins (Treesitter, fzf-native)
  environment.systemPackages = with pkgs; [
    gcc
    gnumake
  ];
}
