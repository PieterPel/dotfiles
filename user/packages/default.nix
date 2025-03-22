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
    inputs.nixvim.homeManagerModules.nixvim
    inputs.spicetify-nix.homeManagerModules.spicetify
    inputs.flatpaks.homeManagerModules.declarative-flatpak
  ];
}

