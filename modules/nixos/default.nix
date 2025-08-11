{ inputs, config, lib, ... }:
{
  imports = [
    ../core
    ./configuration.nix
    ./hyprland.nix
    ./gnome.nix
    ./steam.nix
    ./internationalization.nix
    ./virtualization.nix
    ./sound.nix
    ./thunar.nix
    ./boot.nix
    ./printing.nix
    ./updating.nix

    # TODO: this shouldn't be here
    inputs.home-manager.nixosModules.default
    inputs.sops-nix.nixosModules.sops
    inputs.spicetify-nix.nixosModules.spicetify
    inputs.stylix.nixosModules.stylix
  ];

  config = {
    modules.nixos = lib.mkIf (!config.minimal) {
      boot.enable = true;
      configuration.enable = true;
      gnome.enable = true;
      hyprland.enable = true;
      internationalization.enable = true;
      networking.enable = true;
      printing.enable = true;
      sound.enable = true;
      steam.enable = true;
      thunar.enable = true;
      updating.enable = true;
      virtualization.enable = true;
    };
  };
}
