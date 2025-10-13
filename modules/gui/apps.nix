{
  flake.modules.homeManager.desktop-apps =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      ghosttyPackage = if pkgs.stdenv.isLinux then pkgs.ghostty else pkgs.emptyDirectory;
    in
    {
      config = lib.mkIf config.enableDesktopApps {
        home.packages =
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
    };
}
