{
  ...
}:
let
  nixosRpiModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.modules.profiles.rpi;
      SSIDpasswordFile = "/run/secrets/wifi/HomeNetwork/password";
    in
    {
      options.modules.profiles.rpi = {
        enable = lib.mkEnableOption "Enable RPI profile for NixOS";
      };

      config = lib.mkIf cfg.enable {
        services.openssh = {
          settings.PasswordAuthentication = true;
          settings.PermitRootLogin = "no";
        };

        security.sudo = {
          enable = true;
          wheelNeedsPassword = false;
        };

        networking.wireless = {
          enable = true;
          interfaces = [ "wlan0" ];
        };

        system.nixos.tags =
          let
            rpiCfg = config.boot.loader.raspberryPi;
          in
          lib.mkIf (config.boot.loader.raspberryPi ? variant) [
            "raspberry-pi-${rpiCfg.variant}"
            rpiCfg.bootloader
            config.boot.kernelPackages.kernel.version
          ];
      };
    };
in
{
  flake.modules.nixos.rpi = nixosRpiModule;
}
