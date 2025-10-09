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
      config.flake.modules.darwin.common-options
      # config.flake.modules.darwin.configuration
      config.flake.modules.darwin.home-manager
      # config.flake.modules.darwin.nix
      # config.flake.modules.darwin.aerospace
      # config.flake.modules.darwin.fonts
      # config.flake.modules.darwin.homebrew
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
