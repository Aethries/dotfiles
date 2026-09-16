{ pkgs, ... }:

{
  # ============================================================
  # System Services, Hardware & Daemons
  # ============================================================

  # ----------------------------------------------------------
  # Container Runtime (Docker)
  # ----------------------------------------------------------
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # ----------------------------------------------------------
  # Bluetooth & Hardware Peripherals
  # ----------------------------------------------------------
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  # ----------------------------------------------------------
  # Phone Connect (KDE Connect)
  # Enables device pairing, notification sync, shared clipboard,
  # wireless file transfer, and remote multimedia control.
  # Automatically manages DBus and opens firewall ports (TCP/UDP 1714:1764).
  # ----------------------------------------------------------
  programs.kdeconnect.enable = true;

  # ----------------------------------------------------------
  # Audio Server (PipeWire & WirePlumber)
  # Provides low-latency audio, ALSA/PulseAudio emulation and wpctl
  # ----------------------------------------------------------
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

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

  # ----------------------------------------------------------
  # Cloudflare WARP (warp-cli & warp-svc daemon)
  # ----------------------------------------------------------
  services.cloudflare-warp.enable = true; # Lần đầu dùng: 1111 register && 1111 connect

  # ----------------------------------------------------------
  # 9router DNS Routing (MITM Proxy)
  # Add 9router-managed hostnames here so they survive nixos-rebuild.
  # DO NOT manually edit /etc/hosts — it is a read-only Nix store symlink
  # that gets reset on every rebuild. Use networking.extraHosts instead.
  # The actual entries are also synced at runtime via init-9router.sh.
  # ----------------------------------------------------------
  networking.extraHosts = ''
    127.0.0.1 daily-cloudcode-pa.googleapis.com
    127.0.0.1 cloudcode-pa.googleapis.com
  '';
}
