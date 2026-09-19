{ pkgs, ... }:

let
  kanataHud = pkgs.writers.writePython3Bin "kanata-hud" {
    libraries = with pkgs; [
      python3Packages.pygobject3
      python3Packages.pycairo
      gtk3
      gtk-layer-shell
    ];
    flakeIgnore = [
      "E265"
      "E402"
      "E501"
      "F401"
    ];
  } (builtins.readFile ../scripts/kanata-hud.py);
in
{
  # ============================================================
  # Kanata: Keyboard Remapping Daemon & System-Wide Service
  # ============================================================

  # Enable declarative Kanata systemd service (default passthrough)
  services.kanata = {
    enable = true;
    keyboards.internal = {
      configFile = ../resources/kanata/kanata.kbd;
    };
  };

  # Enable userland input injection via uinput
  hardware.uinput.enable = true;

  # Ensure Kanata binary & HUD overlay are available system-wide
  environment.systemPackages = [
    pkgs.kanata
    kanataHud
  ];

  # Udev rules for Kanata virtual input device and seat integration:
  # Tag virtual devices created by Kanata so seatd and Niri discover them automatically.
  services.udev.extraRules = ''
    KERNEL=="uinput", MODE="0660", GROUP="uinput", TAG+="uaccess"
    SUBSYSTEM=="input", ATTRS{name}=="kanata*", TAG+="seat", TAG+="seat0", TAG+="uaccess", MODE="0660", GROUP="input"
  '';
}
