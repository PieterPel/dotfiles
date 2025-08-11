{ config, lib, ... }:

let
  cfg = config.modules.nixos.boot;
in
{
  options.modules.nixos.boot = {
    enable = lib.mkEnableOption "Enable boot module";
  };

  config = lib.mkIf cfg.enable {
    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.efi.efiSysMountPoint = "/boot";
    boot.kernel.sysctl = {
      # Force redis to work optimally
      "vm.overcommit_memory" = 1;
    };
  };
}
