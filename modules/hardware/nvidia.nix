{ lib, config, pkgs, ... }:

let
  inherit (builtins) elem any;
  inherit (lib) mkIf mkMerge hasPrefix mkDefault mkForce versionOlder;

  nvStable = config.boot.kernelPackages.nvidiaPackages.stable.version;
  nvBeta = config.boot.kernelPackages.nvidiaPackages.beta.version;

  nvidiaPackage =
    if (versionOlder nvBeta nvStable)
    then config.boot.kernelPackages.nvidiaPackages.stable
    else config.boot.kernelPackages.nvidiaPackages.beta;

  hardware = config.opt.hardware.profiles;
in mkMerge [
  (mkIf (any (s: hasPrefix "gpu/nvidia" s) hardware) {

    # services.xserver.videoDrivers = mkDefault [ "nvidia" ];

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = [ pkgs.nvidia-vaapi-driver ];
    };

    hardware.nvidia = {
      open = mkDefault true;
      nvidiaSettings = false;
      forceFullCompositionPipeline = true;
      powerManagement.enable = true;
      modesetting.enable = true;
      package = mkDefault nvidiaPackage;
    };

    # REVIEW: Remove when NixOS/nixpkgs#324921 is backported to stable
    boot.kernelParams = [ "nvidia-drm.fbdev=1" ];
    boot.blacklistedKernelModules = [ "nouveau" ];

    environment.systemPackages = with pkgs; [
    #   (pkgs.writeShellScriptBin "nvidia-settings" ''
    #     mkdir -p "$XDG_CONFIG_HOME/nvidia"
    #     exec ${config.hardware.nvidia.package}/bin/nvidia-settings --config="$XDG_CONFIG_HOME/nvidia/rc.conf" "$@"
    #   '')
      # cudaPackages.cudatoolkit
      nvtopPackages.nvidia

      # mesa
      mesa

      # vulkan
      vulkan-tools
      vulkan-loader
      vulkan-validation-layers
      vulkan-extension-layer

      # libva
      libva
      libva-utils
    ];

    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "nvidia";
      WLR_NO_HARDWARE_CURSORS = "1";
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    };

    environment.variables = {
      # CUDA_PATH = "${pkgs.cudaPackages.cudatoolkit}";
      # CUDA_CACHE_PATH = "$XDG_CACHE_HOME/nv";
    };
  })

  (mkIf (elem "gpu/nvidia/kepler" hardware) {
    hardware.nvidia = {
      open = mkForce false;
      package = mkForce config.boot.kernelPackages.nvidiaPackages.legacy_470;
    };
  })

  (mkIf (elem "gpu/nvidia/turing" hardware) {
    # see NixOS/nixos-hardware#348
    hardware.nvidia = {
      powerManagement.finegrained = true;
      nvidiaPersistenced = true;
    };
  })

  (mkIf (elem "gpu/nvidia/hybrid" hardware) {
    hardware.nvidia = {
      prime.offload = {
        enable = true;
        enableOffloadCmd = true;
      };
    };
  })
]