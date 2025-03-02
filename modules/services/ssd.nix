{ lib, config, pkgs, ... }:

let
  inherit (builtins) elem any attrValues;
  inherit (lib) mkIf mkDefault mkEnableOption;
  cfg = config.opt.services.ssd;
in {
  options.opt.services.ssd = {
    enable = mkEnableOption "useful storage config for ssd";
  };

  config = mkIf cfg.enable {
  services =
    let hasZfs = any (x: x ? fsType && x.fsType == "zfs") (attrValues config.fileSystems);
    in {
      fstrim.enable = mkDefault (!hasZfs);
      zfs.trim.enable = mkDefault hasZfs;
    };
      boot.initrd.availableKernelModules = [ "nvme" ];
  };
}