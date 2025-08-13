{ config
, lib
, ...
}:
{
  config = lib.mkIf config.enableDesktopApps {
    modules.programs = {
      kitty.enable = true;
      hyprland.enable = true;
      wlogout.enable = true;
      rofi.enable = true;
      hyprlock.enable = true;
      vscodium.enable = true;
      waybar.enable = true;
    };
    modules.stylix.enable = true;
  };
}
