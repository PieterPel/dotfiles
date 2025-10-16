{ config, inputs, ... }:

let
  hostname = "nixberry";
in
{
  flake.nixosConfigurations.${hostname} = inputs.nixos-raspberrypi.lib.nixosSystem {
    specialArgs = {
      inherit inputs;
      self = config.flake;
      # NOTE: this is needed
      nixos-raspberrypi = inputs.nixos-raspberrypi;
    };
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      {
        imports = with inputs.nixos-raspberrypi.nixosModules; [
          raspberry-pi-4.base
          usb-gadget-ethernet # Configures USB Gadget/Ethernet - Ethernet emulation over USB
        ];
        inherit hostname;
        system.stateVersion = "25.05"; # Do not change this !
      }
      ./_users
      ./_hardware-configuration.nix
      {
        modules = {
          profiles.rpi.enable = true;
          system = {
            configuration.enable = true;
            internationalization.enable = true;
            updating.enable = true;
          };
          security = {
            sops.enable = true;
          };
          package-management = {
            nix.enable = true;
          };
          virtualization = {
            virtualization.enable = true;
          };
        };
      }
    ];
  };
}
