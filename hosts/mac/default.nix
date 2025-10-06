{ inputs, config, ... }:

let
  hostname = "rebel-pieter";
  system = "aarch64-darwin";
in
{
  flake.darwinConfigurations.${hostname} = inputs.nix-darwin.lib.darwinSystem {
    inherit system;
    specialArgs = {
      inherit inputs;
      self = config.flake;
    };

    modules = [
      config.flake.darwinModules.common-options
      config.flake.darwinModules.configuration
      config.flake.darwinModules.home-manager
      config.flake.darwinModules.nix
      config.flake.darwinModules.aerospace
      config.flake.darwinModules.fonts
      config.flake.darwinModules.homebrew
      ./_users
      {
        inherit hostname;
        system.stateVersion = 6; # Do not change this !
        system.primaryUser = "pieterpel";

        nix.settings.trusted-users = [
          "pieterpel"
        ];

        # Enable darwin modules
        modules.darwin = {
          configuration.enable = true;
          aerospace.enable = true;
          fonts.enable = true;
          homebrew.enable = true;
        };

        modules.core = {
          configuration.enable = true;
          home-manager.enable = true;
          nix.enable = true;
        };
      }
    ];
  };
}
