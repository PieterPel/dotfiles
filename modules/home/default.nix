{ inputs
, ...
}:

{
  imports = [
    ../common-options.nix
    ../programs
    ./options.nix
    ./home.nix
    ./kitty.nix
    ./hyprland
    ./stylix.nix
    ./flatpaks.nix
    ./fish.nix
    ./git.nix
    ./vscodium.nix
    ./waybar.nix
    ./hyprlock.nix
    ./wlogout
    ./rofi

    ./terminal-apps.nix
    ./desktop-apps.nix

    inputs.nixvim.homeModules.nixvim
    inputs.spicetify-nix.homeManagerModules.spicetify
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
  ];
}
