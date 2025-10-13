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
      config.flake.modules.darwin.configuration
      config.flake.modules.darwin.home-manager
      config.flake.modules.darwin.nix
      config.flake.modules.darwin.aerospace
      config.flake.modules.darwin.fonts
      config.flake.modules.darwin.homebrew
      ./_users
      {
        config = {
          inherit hostname;
          system.stateVersion = 6; # Do not change this !
          system.primaryUser = "pieterpel";

          nix.settings.trusted-users = [
            "pieterpel"
          ];

          modules.system.configuration.enable = true;
          modules.wm.aerospace.enable = true;
          modules.system.fonts.enable = true;
          modules.package-management.homebrew.enable = true;
        };
      }
    ];
  };
}
