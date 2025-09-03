{ inputs, pkgs, lib, ... }:

{
  imports = [
    ../common-options.nix
    ../programs
    ./options.nix
    ./home.nix
    ./kitty.nix
    ./stylix.nix
    ./flatpaks.nix
    ./fish.nix
    ./git.nix
    ./vscodium.nix

    ./terminal-apps.nix
    ./desktop-apps.nix

    inputs.nixvim.homeModules.nixvim
    inputs.spicetify-nix.homeManagerModules.spicetify
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
    ./hyprland
    ./waybar.nix
    ./hyprlock.nix
    ./wlogout
    ./rofi
  ];
}
