{ inputs
, ...
}:

{
  imports = [
    # TODO: this shouldn't be here
    inputs.home-manager.darwinModules.home-manager
    inputs.spicetify-nix.darwinModules.spicetify
    inputs.sops-nix.darwinModules.sops
    inputs.spicetify-nix.darwinModules.spicetify
  ];
}
