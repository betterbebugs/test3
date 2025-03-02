{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.opt.services.pipewire;
  home = config.home-manager.users.${config.opt.system.username};
in {
  options.opt.services.pipewire = {
    enable = mkEnableOption "PipeWire sound server";
  };

  config = mkIf cfg.enable {
    opt.home.packages = with pkgs; [pulseaudio];
    # environment.systemPackages = with pkgs; [pulseaudio];
    services = {
      pipewire = {
        enable = true;
        pulse.enable = true;
        jack.enable = true;
        alsa = {
          enable = true;
          support32Bit = true;
        };
      };
    };
  };
}