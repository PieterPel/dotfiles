{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.modules.darwin.fonts;
in
{
  options.modules.darwin.fonts = {
    enable = lib.mkEnableOption "Enable fonts module";
  };

  config = lib.mkIf cfg.enable {
    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      font-awesome
      sketchybar-app-font
    ];
  };
}
