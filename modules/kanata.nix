{ pkgs, ... }:

let
  pythonEnv = pkgs.python3.withPackages (
    ps: with ps; [
      pygobject3
      pycairo
    ]
  );

  kanataHud = pkgs.stdenv.mkDerivation {
    pname = "kanata-hud";
    version = "1.0.0";

    nativeBuildInputs = [
      pkgs.wrapGAppsHook3
      pkgs.gobject-introspection
    ];

    buildInputs = [
      pkgs.gtk3
      pkgs.gtk-layer-shell
      pythonEnv
    ];

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/bin
      cp ${../scripts/kanata-hud.py} $out/bin/kanata-hud
      chmod +x $out/bin/kanata-hud
      sed -i "1s|^.*$|#!${pythonEnv}/bin/python3|" $out/bin/kanata-hud
    '';
  };
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

  # Auto-restart daemon on crash or exit for stable recovery
  systemd.services.kanata-internal.serviceConfig = {
    Restart = "always";
    RestartSec = "2s";
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
