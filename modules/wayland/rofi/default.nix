{ config
, ...
}:
{
  flake.modules.homeManager.rofi =
    { lib, ... }:
    {
      options.modules.wayland.rofi = {
        enable = lib.mkEnableOption "Enable Rofi configuration.";
      };
      imports = [
        config.flake.modules.homeManager."rofi-config-long"
        config.flake.modules.homeManager."rofi-config"
      ];
    };
}

