{ config, lib, ... }:

{
  imports = [
    ../common-options.nix
    ./configuration.nix
    ./home-manager.nix
    ./stylix.nix
    ./fonts.nix
    ./sops.nix
    ./nix.nix
  ];

  modules.core = lib.mkIf (!config.minimal) {
    configuration.enable = true;
    fonts.enable = true;
    home-manager.enable = true;
    nix.enable = true;
    sops.enable = true;
    stylix.enable = true;
  };
}
