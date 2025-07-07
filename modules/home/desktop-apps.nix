{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./kitty.nix
    ./hyprland
    ./vscodium.nix
    ./waybar.nix
    ./wlogout
    ./rofi
    ./spicetify.nix
    ./flatpaks.nix
    ./zed.nix
    ./stylix.nix
    inputs.spicetify-nix.homeManagerModules.spicetify
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
  ];

  home.packages =
    with pkgs;
    if config.enableDesktopApps then
      [
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
      ]
    else
      [ ];
}
