{
  flake.modules.homeModules.desktop-apps = { config, lib, pkgs, ... }:
    let
      ghosttyPackage = if pkgs.stdenv.isLinux then pkgs.ghostty else pkgs.emptyDirectory;
    in
    {
      config = lib.mkIf config.enableDesktopApps {
        modules.programs = {
          spicetify.enable = false;
          zed.enable = true;
          kitty.enable = true;
          hyprland.enable = true;
          vscodium.enable = true;
          wlogout.enable = true;
          rofi.enable = true;
          hyprlock.enable = true;
          waybar.enable = true;
          sketchybar.enable = false; # WARNING: very sketchy/broken
        };
        modules.stylix.enable = true;

        home.packages = with pkgs; [
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
