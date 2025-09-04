{ inputs
, ...
}:

{
  imports = [
    ../core
    ../programs/options.nix
    ./configuration.nix
    ./homebrew.nix
    ./fonts.nix

    inputs.home-manager.darwinModules.home-manager
    inputs.spicetify-nix.darwinModules.spicetify
    inputs.sops-nix.darwinModules.sops
    inputs.stylix.darwinModules.stylix
    inputs.nixvim.nixDarwinModules.nixvim
  ];

  modules.darwin = {
    configuration.enable = true;
    homebrew.enable = true;
    fonts.enable = true;
  };
}
