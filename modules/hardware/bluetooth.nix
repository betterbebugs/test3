{ lib, config, pkgs, ... }:

let
  inherit (builtins) elem;
  inherit (lib) mkIf;
in mkIf (elem "bluetooth" config.opt.hardware.profiles) {
  hardware.bluetooth.enable = true;

  # Brute force a reset after waking up from sleep, as some bluetooth devices
  # will fail to connect to a system that's been suspended at some point.
#   powerManagement.resumeCommands = ''
#     ${pkgs.util-linux}/bin/rfkill block bluetooth
#     ${pkgs.util-linux}/bin/rfkill unblock bluetooth
#   '';
}