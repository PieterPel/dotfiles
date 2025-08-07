{ inputs, ... }:

let
  hostname = "nixberry";
in
{
  flake.nixosConfigurations.${hostname} = inputs.nixos-raspberrypi.lib.nixosSystemFull {
    specialArgs = inputs;
    modules = [
      {
        imports = with inputs.nixos-raspberrypi.nixosModules; [
          raspberry-pi-4.base
          usb-gadget-ethernet # Configures USB Gadget/Ethernet - Ethernet emulation over USB
        ];
        inherit hostname;
        system.stateVersion = "25.05"; # Do not change this !
      }

      ../../modules/minimal
      ../../profiles/system/rpi
      ./users

    ];
  };

}
