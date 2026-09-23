{ ... }:

{
  imports = [
    ./services/containers.nix
    ./services/audio.nix
    ./services/ai-gateways.nix
    ./services/agent-memory.nix
  ];

  # ============================================================
  # General system services and peripherals
  # ============================================================

  # ----------------------------------------------------------
  # Bluetooth & Hardware Peripherals
  # ----------------------------------------------------------
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  users.users.greeter.extraGroups = [
    "input"
    "video"
  ];

  # ----------------------------------------------------------
  # Phone Connect (KDE Connect)
  # Enables device pairing, notification sync, shared clipboard,
  # wireless file transfer, and remote multimedia control.
  # Automatically manages DBus and opens firewall ports (TCP/UDP 1714:1764).
  # ----------------------------------------------------------
  programs.kdeconnect.enable = true;

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
  services.gnome.sushi.enable = true;

  # ----------------------------------------------------------
  # Cloudflare WARP (warp-cli & warp-svc daemon)
  # ----------------------------------------------------------
  services.cloudflare-warp.enable = true; # Lần đầu dùng: 1111 register && 1111 connect

}
