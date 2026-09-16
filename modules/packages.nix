{ pkgs, ... }@args:

let
  inputs = args.inputs or null;
  lock = builtins.fromJSON (builtins.readFile ../flake.lock);
  getLockedFlake =
    name:
    let
      node = lock.nodes.${name}.locked;
    in
    builtins.getFlake "github:${node.owner}/${node.repo}/${node.rev}";

  llmAgentsFlake =
    if (inputs != null && inputs ? llm-agents) then inputs.llm-agents else getLockedFlake "llm-agents";

  antigravityFlake =
    if (inputs != null && inputs ? antigravity-nix) then
      inputs.antigravity-nix
    else
      getLockedFlake "antigravity-nix";

  antigravityIdeNoFhs =
    antigravityFlake.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-ide-no-fhs;

  antigravityIde =
    (antigravityFlake.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-ide).overrideAttrs
      (old: {
        postFixup = (old.postFixup or "") + ''
                substituteInPlace $out/share/applications/antigravity-ide.desktop \
                  --replace-fail "MimeType=x-scheme-handler/antigravity" "MimeType=x-scheme-handler/antigravity;x-scheme-handler/antigravity-ide;"

                cat << 'EOF' > $out/share/applications/antigravity-ide-url-handler.desktop
          [Desktop Entry]
          Categories=Development;IDE;
          Comment=Google Antigravity IDE URL Handler
          Exec=antigravity-ide --open-url %U
          Icon=antigravity-ide
          MimeType=x-scheme-handler/antigravity;x-scheme-handler/antigravity-ide;
          Name=Google Antigravity IDE - URL Handler
          NoDisplay=true
          StartupNotify=true
          Type=Application
          Version=1.5
          EOF

                # Wrap launcher to inject custom workbench HTML & CSS overlay via bwrap
                if [ -L "$out/bin/antigravity-ide" ]; then
                  origTarget=$(readlink -f "$out/bin/antigravity-ide")
                  rm "$out/bin/antigravity-ide"
                  workbenchDir="${antigravityIdeNoFhs}/lib/google-antigravity-ide/resources/app/out/vs/code/electron-browser/workbench"
                  substitute "$origTarget" "$out/bin/antigravity-ide" \
                    --replace-fail "--bind-try /etc/nixos/ /etc/nixos/" \
                    "--ro-bind-try \$HOME/.config/antigravity/product.json ${antigravityIdeNoFhs}/lib/google-antigravity-ide/resources/app/product.json --ro-bind-try \$HOME/.config/antigravity/workbench.html $workbenchDir/workbench.html --ro-bind-try \$HOME/.config/antigravity/workbench-jetski-agent.html $workbenchDir/workbench-jetski-agent.html --bind-try /etc/nixos/ /etc/nixos/"
                  chmod +x "$out/bin/antigravity-ide"
                fi
        '';
      });
  antigravityCli = llmAgentsFlake.packages.${pkgs.stdenv.hostPlatform.system}.antigravity-cli;

  lark = pkgs.callPackage ../pkgs/lark.nix { };

in
{
  # ============================================================
  # Tập trung toàn bộ packages hệ thống tại đây để dễ quản lý
  # ============================================================
  environment.systemPackages = with pkgs; [
    # ----------------------------------------------------------
    # CLI Utilities & System Tools
    # ----------------------------------------------------------
    curl
    wget
    git
    git-lfs
    gh
    gh-dash
    jq
    starship
    wl-clipboard
    xclip
    openssl
    age
    zstd
    lsof
    rclone

    # ----------------------------------------------------------
    # Modern Terminal & Fullstack/DevOps Utilities
    # ----------------------------------------------------------
    broot
    yazi
    zoxide
    delta
    lazygit
    lazydocker
    k9s
    jira-cli-go
    fastfetch
    bat
    eza
    ripgrep
    fd
    fzf
    bottom
    dust
    duf
    tealdeer
    xh
    gping
    tokei
    yq-go
    trash-cli
    cloudflared
    lsof # Required by 9router MITM proxy (also symlinked to /usr/bin/lsof by init-9router.sh)
    nssTools # Provides certutil for 9router browser trust store registration

    # ----------------------------------------------------------
    # Node.js, Package Managers & Version Management (NVM)
    # ----------------------------------------------------------
    # nodejs_22 — managed by fnm instead; run: fnm install --lts
    corepack
    pnpm
    yarn
    fnm

    # ----------------------------------------------------------
    # Screenshot, Hardware & System Peripherals
    # ----------------------------------------------------------
    brightnessctl
    playerctl
    libnotify
    pavucontrol
    satty
    grim
    slurp
    hyprpicker
    wayfreeze
    swayidle
    wf-recorder
    libva-utils

    # ----------------------------------------------------------
    # Keyring & Secret Management
    # ----------------------------------------------------------
    seahorse

    # ----------------------------------------------------------
    # Desktop Applications & GUI
    # ----------------------------------------------------------
    (google-chrome.override {
      commandLineArgs = [
        "--password-store=gnome-libsecret"
      ];
    })
    kitty
    bibata-cursors
    telegram-desktop
    slack
    lark
    obsidian
    postman
    # beekeeper-studio — EOL/insecure; dùng Flatpak thay thế: flatpak install flathub io.beekeeperstudio.Studio

    # ----------------------------------------------------------
    # Editors & AI Tools
    # ----------------------------------------------------------
    neovide
    antigravityIde
    antigravityCli
    codex
    fuzzel
  ];
}
