{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.modules.core.fonts;
in
{
  options.modules.core.fonts = {
    enable = lib.mkEnableOption "Enable fonts module";
  };

  config = lib.mkIf cfg.enable {
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      font-awesome
    ];

    fonts = {
      fontconfig = {
        antialias = true;

        # Fixes antialiasing blur
        hinting = {
          enable = true;
          style = "full"; # no difference
          autohint = true; # no difference
        };

        subpixel = {
          # Makes it bolder
          rgba = "rgb";
          lcdfilter = "default"; # no difference
        };
      };
    };
  };
}
