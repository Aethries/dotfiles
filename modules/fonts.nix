{ pkgs, ... }:

{
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      # Monospace & Coding Fonts with Icons
      nerd-fonts.jetbrains-mono

      # UI & General Document Reading Fonts (Vietnamese & Latin)
      inter
      noto-fonts
      noto-fonts-cjk-sans

      # Emoji
      noto-fonts-color-emoji
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [
          "JetBrainsMono Nerd Font Mono"
          "JetBrainsMono Nerd Font"
        ];
        sansSerif = [
          "Inter"
          "Noto Sans"
        ];
        serif = [
          "Noto Serif"
        ];
        emoji = [
          "Noto Color Emoji"
        ];
      };
    };
  };
}
