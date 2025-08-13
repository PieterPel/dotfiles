{ pkgs
, config
, lib
, ...
}:
{
  config = lib.mkIf config.enableDesktopApps {
    modules.programs = {
      kitty.enable = true;
      hyprland.enable = true;
      vscodium.enable = true;
      waybar.enable = true;
      wlogout.enable = true;
      rofi.enable = true;
      spicetify.enable = true;
      zed.enable = true;
      hyprlock.enable = true;
    };
    modules.stylix.enable = true;

    home.packages = with pkgs; [
      # Screenshots
      grim
      slurp
      swappy

      # Photoshop
      gimp

      # Font
      montserrat

      # Browser
      brave
      chromium

      # Editor
      libreoffice-qt6-fresh

      # Notes
      logseq

      # Messaging
      legcord
    ];
  };
}
