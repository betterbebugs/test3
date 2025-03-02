{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkEnableOption mkDefault attrsets strings;
  cfg = config.opt.system.roles;
  mkTrue = l: lib.mkMerge (builtins.map (x: (attrsets.setAttrByPath (strings.splitString "." x) (mkDefault true))) l); # True...
#   g = s: "programs.${s}.enable"; # g
in {
  options.opt.system.roles = {
    workstation = mkEnableOption "full suite of software for day-to-day desktop use";
  };

  config.opt = lib.mkMerge [
    (mkIf cfg.workstation (mkTrue [
      "services.pipewire.enable"
      "services.ssd.enable"
    ]))
  ];
}