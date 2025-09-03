{ pkgs
, config
, lib
, ...
}:
{
  config = lib.mkIf config.enableDesktopApps {
    modules.programs = {
      spicetify.enable = true;
      zed.enable = true;
    };

    packages = with pkgs; [
      # Photoshop
      gimp

      # Font
      montserrat

      # Browser
      brave
      # chromium

      # Editor
      #libreoffice-qt6-fresh

      # Notes
      logseq

      # Messaging
      # legcord

      # Partitioning
      #gparted
    ] ++ lib.optionals pkgs.stdenv.isLinux [
      # Screenshots
      grim
      slurp
      swappy
    ];
  };
}
