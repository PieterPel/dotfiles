{ config, pkgs, inputs, ... }:

{

  imports = [
    ./nixvim.nix
    ./kitty.nix
    ./hyprland/default.nix
    ./vscodium.nix
    inputs.nixvim.homeManagerModules.nixvim
  ];
}

