{ config, pkgs, inputs, ... }:

{

  imports = [
    ./nixvim.nix
    ./kitty.nix
    ./hyprland
    ./vscodium.nix
    ./waybar.nix
    ./wlogout
    ./steam.nix
    ./rofi
    inputs.nixvim.homeManagerModules.nixvim
  ];
}

