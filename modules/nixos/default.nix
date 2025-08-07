{ inputs, ... }:
{
  imports = [
    ../core
    ./configuration.nix
    ./hyprland.nix
    ./gnome.nix
    ./steam.nix

    # TODO: this shouldn't be here
    inputs.home-manager.nixosModules.default
    inputs.sops-nix.nixosModules.sops
    inputs.spicetify-nix.nixosModules.spicetify
    inputs.stylix.nixosModules.stylix
  ];

}
