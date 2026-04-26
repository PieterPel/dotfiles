{
  flake.modules.nixos.boot = { config, lib, ... }:
    let
      cfg = config.modules.system.boot;
    in
    {
      options.modules.system.boot = {
        enable = lib.mkEnableOption "Enable boot module";
      };

      config = lib.mkIf cfg.enable {
        boot = {
          # Bootloader.
          loader = {
            systemd-boot.enable = true;
            efi = {
              canTouchEfiVariables = true;
              efiSysMountPoint = "/boot";
            };
          };
          kernel.sysctl = {
            # Force redis to work optimally
            "vm.overcommit_memory" = 1;
          };
        };
      };
    };
}
