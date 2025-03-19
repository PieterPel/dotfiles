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
    inputs.nixvim.homeManagerModules.nixvim
  ];
}

