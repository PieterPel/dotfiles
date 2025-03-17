{ config, pkgs, inputs, ... }:

{

  imports = [
    ./nixvim.nix
    ./kitty.nix
    ./hyprland/default.nix
    inputs.nixvim.homeManagerModules.nixvim
  ];
}

