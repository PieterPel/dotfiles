{ config, inputs, ... }:

let
  hostname = "ideapad";
  system = "x86_64-linux";
in
{
  flake.nixosConfigurations.${hostname} = inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = {
      # TODO: also flake-partsify the user modules?
      self = config.flake;
    };

    modules = [
      ./hardware-configuration.nix
      ./_users
      {
        inherit hostname;
        modules.profiles.laptop.enable = true;
        services.fprintd = {
          enable = true;
        };

        system.stateVersion = "24.11"; # Do not change this !
      }
    ];
  };
}
