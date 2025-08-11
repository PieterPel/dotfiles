{ config, lib, pkgs, ... }:

let
  cfg = config.modules.core.stylix;
in
{
  options.modules.core.stylix = {
    enable = lib.mkEnableOption "Enable stylix module";
  };

  config = lib.mkIf cfg.enable {

    environment.systemPackages = with pkgs; [
      base16-schemes
    ];

    stylix = {
      enable = true;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/purpledream.yaml";
      image = ../../wallpapers/tux-teaching.jpg;
      polarity = "dark";
    };
  };
}
