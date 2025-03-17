{ config, pkgs, inputs, ... }:

{

  imports = [
    ./nixvim.nix
    ./kitty.nix
    ./hyprland/default.nix
    ./vscodium.nix
    ./waybar.nix
    inputs.nixvim.homeManagerModules.nixvim
  ];
}

