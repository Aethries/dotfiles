{ lib, ... }:

{
  options.dotfiles.primaryUser = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = "Primary normal user for machine-local desktop integrations.";
  };

  config = {
    nixpkgs.config.allowUnfree = true;
    networking.networkmanager.enable = true;
    programs.nix-ld.enable = true;
    documentation.nixos.enable = false;
    environment.localBinInPath = true;

    # Trusted Root CA Certificates (9router MITM Proxy)
    security.pki.certificateFiles = [
      ../resources/certs/9router-rootCA.crt
    ];

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
  };

}
