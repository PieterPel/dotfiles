{ config, pkgs, inputs, ... }:

{
  imports = [
    ./nixvim.nix
    ./kitty.nix
    ./hyprland
    ./vscodium.nix
    ./waybar.nix
    ./wlogout
    ./rofi
    ./spicetify.nix 
    ./direnv.nix
    ./fish.nix
    ./tmux.nix
    ./git.nix
    ./flatpaks.nix
    inputs.nixvim.homeManagerModules.nixvim
    inputs.spicetify-nix.homeManagerModules.spicetify
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
  ];
}

