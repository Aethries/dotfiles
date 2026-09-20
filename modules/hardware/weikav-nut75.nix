{ config, lib, ... }:

{
  # WEIKAV NUT75 requires seatd because systemd-logind rejects its malformed
  # device metadata on affected systemd versions.
  services.seatd = {
    enable = true;
    group = "seat";
  };

  environment.sessionVariables.LIBSEAT_BACKEND = "seatd";

  users.users = lib.mkMerge [
    {
      greeter.extraGroups = [ "seat" ];
    }
    (lib.mkIf (config.dotfiles.primaryUser != null) {
      "${config.dotfiles.primaryUser}".extraGroups = lib.mkAfter [ "seat" ];
    })
  ];

  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="input", ATTRS{idVendor}=="0c45", ATTRS{idProduct}=="fef9|880c", ENV{ID_INPUT_KEY}="1", ENV{ID_INPUT_KEYBOARD}="1"
    ACTION=="add|change", SUBSYSTEM=="input", KERNEL=="event*", ATTRS{idVendor}=="0c45", ATTRS{idProduct}=="fef9|880c", TAG+="seat", TAG+="seat0", TAG+="uaccess", MODE="0660", GROUP="input"
  '';
}
