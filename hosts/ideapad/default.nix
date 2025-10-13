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
      # ../../modules/nixos-x86 # This is probably not needed anymore if modules are enabled explicitly
      ./hardware-configuration.nix
      ./users
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
