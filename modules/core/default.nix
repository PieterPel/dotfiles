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

  config = lib.mkIf (!config.minimal) {
    modules.core = {
      configuration.enable = true;
      fonts.enable = true;
      home-manager.enable = true;
      nix.enable = true;
      sops.enable = true;
      stylix.enable = true;
    };
  };
}
