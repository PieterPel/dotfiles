{ config, inputs, ... }:

let
  hostname = "nixberry";
in
{
  flake.nixosConfigurations.${hostname} = inputs.nixos-raspberrypi.lib.nixosSystem {
    inherit (inputs) nixpkgs;
    specialArgs = {
      inherit inputs;
      self = config.flake;
      # NOTE: this is needed
      inherit (inputs) nixos-raspberrypi;
    };
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      {
        imports = with inputs.nixos-raspberrypi.nixosModules; [
          raspberry-pi-4.base
          usb-gadget-ethernet # Configures USB Gadget/Ethernet - Ethernet emulation over USB
          # RPi-optimized packages (kodi, ffmpeg, libcamera, vlc, ...) into the
          # global pkgs scope, per the flake's own README -- without this,
          # `pkgs.kodi*` was always plain generic nixpkgs, not their tuned build.
          inputs.nixos-raspberrypi.lib.inject-overlays
          trusted-nix-caches
          nixpkgs-rpi
          inputs.nixos-raspberrypi.lib.inject-overlays-global
        ];
        inherit hostname;
        system.stateVersion = "25.05"; # Do not change this !
      }
      ./_users
      ./_hardware-configuration.nix
      {
        modules = {
          profiles.rpi.enable = true;
          gaming.retroarch.enable = true;
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
