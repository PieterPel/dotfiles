{ inputs
, ...
}:

{
  imports = [
    ../core
    inputs.home-manager.darwinModules.home-manager
    inputs.spicetify-nix.darwinModules.spicetify
    inputs.sops-nix.darwinModules.sops
    inputs.stylix.darwinModules.stylix
  ];
}
