{ inputs
, ...
}:

{
  imports = [
    ../core
    ./configuration.nix
    ./homebrew.nix
    inputs.home-manager.darwinModules.home-manager
    inputs.spicetify-nix.darwinModules.spicetify
    inputs.sops-nix.darwinModules.sops
    inputs.stylix.darwinModules.stylix
    inputs.nixvim.darwinModules.nixvim
  ];

  modules.darwin = {
    configuration.enable = true;
    homebrew.enable = true;
  };
}
