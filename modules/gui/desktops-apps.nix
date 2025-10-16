{
  flake.modules.homeManager.desktop-apps =
    {
      config,
      lib,
      pkgs,
      ...
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
            # Photoshop
            gimp

            # Font
            montserrat

            # Browser
            brave
          ]
          ++ lib.optionals pkgs.stdenv.isLinux [
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
