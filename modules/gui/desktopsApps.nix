let
  module = "desktopApps";
  parent = "gui";
in
{
  flake.modules.homeManager.${module} =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.modules.${parent}.${module};
    in
    {
      options.modules.${parent}.${module} = {
        enable = lib.mkEnableOption "Enable desktop apps module";
      };
      config = lib.mkIf cfg.enable {
        packages =
          with pkgs;
          [
            # Font
            montserrat

            # Browser
            brave
          ]
          ++ lib.optionals pkgs.stdenv.isLinux [
            # Photoshop
            gimp

            # Browser
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
