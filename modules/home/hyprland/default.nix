{ config, lib, ... }:
{
  flake.homeModules.hyprland = { ... }:
    {
      imports = [
        ./_binds.nix
        ./_hyprland.nix
      ];
    };
}
