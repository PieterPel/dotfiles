{
  flake.modules.homeManager.desktop-apps =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.modules.gui.desktop-apps;
    in
    {
      options.modules.gui.desktop-apps = {
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
