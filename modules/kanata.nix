{ pkgs, ... }:

{
  # ============================================================
  # Kanata: Keyboard Remapping Daemon & System-Wide Vim Modal Layer
  # ============================================================

  # Enable declarative Kanata systemd service
  services.kanata = {
    enable = true;
    keyboards.internal = {
      configFile = ../resources/kanata/kanata.kbd;
      extraArgs = [
        "--log-layer-changes"
      ];
    };
  };

  # Enable userland input injection via uinput
  hardware.uinput.enable = true;

  # Ensure Kanata binary is available system-wide for CLI & validation
  environment.systemPackages = [
    pkgs.kanata
  ];

  # Udev rules for Kanata virtual input device and seat integration:
  # Tag virtual devices created by Kanata so seatd and Niri discover them automatically.
  services.udev.extraRules = ''
    KERNEL=="uinput", MODE="0660", GROUP="uinput", TAG+="uaccess"
    SUBSYSTEM=="input", ATTRS{name}=="kanata*", TAG+="seat", TAG+="seat0", TAG+="uaccess", MODE="0660", GROUP="input"
  '';
}
