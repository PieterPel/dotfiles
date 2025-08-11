{ lib
, config
, ...
}:
{
  imports = [
    ../nixos
    ./gnome.nix
    ./hyprland.nix
  ];

  modules.nixos-x86 = lib.mkIf (!config.minimal) {
    gnome.enable = true;
    hyprland.enable = true;
  };
}
