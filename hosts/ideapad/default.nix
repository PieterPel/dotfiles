{ inputs, ... }:

let
  hostname = "ideapad";
  system = "x86_64-linux";
in
{
  flake.nixosConfigurations.${hostname} = inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = {
      inherit inputs;
    };

    modules = [
      ../../modules/nixos-x86
      ../../profiles/system/laptop
      ./hardware-configuration.nix
      ./users
      {
        inherit hostname;
        services.fprintd = {
          enable = true;
        };

        system.stateVersion = "24.11"; # Do not change this !
      }
    ];
  };
}
