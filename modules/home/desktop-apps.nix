{ config
, lib
, pkgs
, ...
}:
let
  ghosttyPackage = if pkgs.stdenv.isLinux then pkgs.ghostty else pkgs.emptyDirectory;
in
{
  config = lib.mkIf config.enableDesktopApps {
    modules.programs = {
      kitty.enable = true;
      hyprland.enable = true;
      vscodium.enable = true;
      wlogout.enable = true;
      rofi.enable = true;
      hyprlock.enable = true;
      waybar.enable = true;
    };
    modules.stylix.enable = true;

    programs.ghostty = {
      enable = true;
      package = ghosttyPackage;
      enableFishIntegration = true;
      enableZshIntegration = true;
      settings = {
        command = lib.getExe pkgs.fish;
      };
    };
  };
}
