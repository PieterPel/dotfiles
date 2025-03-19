{ config, pkgs, inputs, ... }:

{

  imports = [
    ./nixvim.nix
    ./kitty.nix
    ./hyprland/default.nix
    ./vscodium.nix
    ./waybar.nix
    ./wlogout/default.nix
    inputs.nixvim.homeManagerModules.nixvim
  ];
}

