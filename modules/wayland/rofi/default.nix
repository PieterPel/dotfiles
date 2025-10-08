{ config, lib, ... }:
{
  flake.homeModules.rofi = { ... }:
    {
      imports = [
        ./_config-long.nix
        ./_rofi.nix
      ];
    };
}
