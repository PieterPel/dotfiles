{ config, lib, ... }:
{
  flake.homeModules.desktop-apps-programs = { config, lib, pkgs, ... }:
    {
      config = lib.mkIf config.enableDesktopApps {
        modules.programs = {
          spicetify.enable = false;
          zed.enable = true;
        };

        packages =
          with pkgs;
          [
            # Photoshop
            gimp

            # Font
            montserrat

            # Browser
            brave

          ]
          ++ lib.optionals pkgs.stdenv.isLinux [
            chromium
            # Screenshots
            grim
            slurp
            swappy

            # Editor
            libreoffice-qt6-fresh

            # Partitioning
            gparted

            # Messaging
            legcord
          ];
      };
    };
}
