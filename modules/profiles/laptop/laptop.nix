{ ...
}:
let
  nixosLaptopModule =
    { config, lib, ... }:
    let
      cfg = config.modules.profiles.laptop;
    in
    {
      options.modules.profiles.laptop = {
        enable = lib.mkEnableOption "Enable laptop profile for NixOS";
      };

      config = lib.mkIf cfg.enable {
        # services.logind.settings.Login = {
        #   HandleLidSwitch = "poweroff";
        #   HandleLidSwitchExternalPower = "lock";
        #   HandleLidSwitchDocked = "ignore";
        # };
        powerManagement.enable = true;
      };
    };

  homeManagerLaptopModule =
    { config, lib, ... }:
    let
      cfg = config.modules.profiles.laptop;
    in
    {
      options.modules.profiles.laptop = {
        enable = lib.mkEnableOption "Enable laptop profile for Home Manager";
      };

      config = lib.mkIf cfg.enable { };
    };
in
{
  flake.modules.nixos.laptop = nixosLaptopModule;
  flake.modules.homeManager.laptop = homeManagerLaptopModule;
}
