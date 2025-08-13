{ pkgs
, config
, lib
, ...
}:
{
  config = lib.mkIf config.enableDesktopApps {
    modules.programs = {
      rofi.enable = true;
      spicetify.enable = true;
      zed.enable = true;
    };

    packages = with pkgs; [
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
