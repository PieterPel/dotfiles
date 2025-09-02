{ inputs, ... }:

let
  hostname = "mac";
in
{
  flake.darwinConfigurations.${hostname} = inputs.nix-darwin.lib.darwinSystem {
    specialArgs = {
      inherit inputs;
    };

    modules = [
      ../../modules/darwin
      {
        inherit hostname;
        system.stateVersion = 6 # Do not change this !
          }
          ];
      };
      }
