{ inputs, ... }:

let
  hostname = "rebel-pieter";
  system = "aarch64-darwin";
in
{
  flake.darwinConfigurations.${hostname} = inputs.nix-darwin.lib.darwinSystem {
    inherit system;
    specialArgs = {
      inherit inputs;
    };

    modules = [
      ../../modules/darwin
      ./users
      {
        inherit hostname;
        system.stateVersion = 6; # Do not change this !
        system.primaryUser = "pieterpel";

        nix.settings.trusted-users = [
          "pieterpel"
        ];
      }
    ];
  };
}
