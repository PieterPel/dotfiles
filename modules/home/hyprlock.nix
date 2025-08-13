{ config
, lib
, ...
}:

let
  cfg = config.modules.programs.hyprlock;
  wallpaper = ../../wallpapers/tux-teaching.jpg;
  face = ../../img/face.jpg;
in
{
  options.modules.programs.hyprlock = {
    enable = lib.mkEnableOption "Enable Hyprlock configuration.";
  };

  config = lib.mkIf cfg.enable {
    programs.hyprlock = {
      enable = true;
      settings = {
        general = {
          disable_loading_bar = true;
          grace = 10;
          hide_cursor = true;
          no_fade_in = false;
        };
        background = lib.mkForce [
          {
            path = "${wallpaper}";
            blur_passes = 3;
            blur_size = 8;
          }
        ];
        image = lib.mkForce [
          {
            path = "${face}";
            size = 150;
            border_size = 4;
            border_color = "rgb(${config.lib.stylix.colors.base0A})";
            rounding = -1; # Negative means circle
            position = "0, 200";
            halign = "center";
            valign = "center";
          }
        ];
        input-field = lib.mkForce [
          {
            size = "200, 50";
            position = "0, -80";
            monitor = "";
            dots_center = true;
            fade_on_empty = false;
            font_color = "rgb(${config.lib.stylix.colors.base01})";
            inner_color = "rgb(${config.lib.stylix.colors.base06})";
            outer_color = "rgb(${config.lib.stylix.colors.base0A})";
            outline_thickness = 5;
            placeholder_text = "Password...";
            shadow_passes = 2;
          }
        ];
      };
    };
  };
}
