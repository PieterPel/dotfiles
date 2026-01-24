{ ... }:
let
  nixosModule = { lib, config, pkgs, ... }: {
    options.modules.system.fonts = {
      enable = lib.mkEnableOption "Enable fonts module";
    };
    config = lib.mkIf config.modules.system.fonts.enable {
      fonts.packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        font-awesome
      ];
      fonts.fontconfig = {
        antialias = true;
        hinting = {
          enable = true;
          style = "full";
          autohint = true;
        };
        subpixel = {
          rgba = "rgb";
          lcdfilter = "default";
        };
      };
    };
  };

  darwinModule = { lib, config, pkgs, ... }: {
    options.modules.system.fonts = {
      enable = lib.mkEnableOption "Enable fonts module";
    };
    config = lib.mkIf config.modules.system.fonts.enable {
      fonts.packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        font-awesome
        sketchybar-app-font
      ];
    };
  };
in
{
  flake.modules.nixos.fonts = nixosModule;
  flake.modules.darwin.fonts = darwinModule;
}
