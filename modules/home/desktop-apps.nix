{ pkgs
, config
, inputs
, lib
, ...
}:
{
  imports = [
    ./kitty.nix
    ./hyprland
    ./stylix.nix
    ./wlogout
    ./flatpaks.nix
    ../programs/vscodium.nix
    ../programs/waybar.nix
    ../programs/rofi
    ../programs/spicetify.nix
    ../programs/zed.nix
    ../programs/hyprlock.nix
    inputs.spicetify-nix.homeManagerModules.spicetify
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
  ];

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
