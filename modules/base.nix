{ pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [
    "usbcore.autosuspend=-1"
    "hid_apple.fnmode=0"
  ];

  nixpkgs.config.allowUnfree = true;
  networking.networkmanager.enable = true;
  programs.nix-ld.enable = true;
  documentation.nixos.enable = false;
  environment.localBinInPath = true;

  # (Lưu ý: SSH Agent được cung cấp và tự động mở khóa qua services.gnome.gcr-ssh-agent từ modules/desktop.nix)

  # ----------------------------------------------------------
  # Nix Settings & Automatic Garbage Collection (Tự dọn rác)
  # ----------------------------------------------------------
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      extra-substituters = [ "https://noctalia.cachix.org" ];
      extra-trusted-public-keys = [
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      ];
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  system.stateVersion = "26.05";
}
