{ config, lib, ... }:
{
  flake.homeModules.nixvim = { ... }:
    {
      imports = [
        ./_binds.nix
        ./_plugins.nix
        ./_settings.nix
      ];
    };
}

