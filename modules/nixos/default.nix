{ inputs
, config
, lib
, ...
}:
{
  imports = [
    ../core
    ./configuration.nix
    ./steam.nix
    ./internationalization.nix
    ./virtualization.nix
    ./sound.nix
    ./thunar.nix
    ./boot.nix
    ./printing.nix
    ./networking.nix
    ./updating.nix

    inputs.home-manager.nixosModules.default
    inputs.sops-nix.nixosModules.sops
    inputs.spicetify-nix.nixosModules.spicetify
    inputs.stylix.nixosModules.stylix
    inputs.nixvim.nixosModules.nixvim
  ];

  modules.nixos = lib.mkIf (!config.minimal) {
    boot.enable = true;
    configuration.enable = true;
    internationalization.enable = true;
    networking.enable = true;
    printing.enable = true;
    sound.enable = true;
    steam.enable = true;
    thunar.enable = true;
    updating.enable = true;
    virtualization.enable = true;
  };
}
