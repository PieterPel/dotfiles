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
          # Kernel, firmware, bootloader and vendor packages. Scoped -- these
          # are things only this host uses, so they don't cascade.
          inputs.nixos-raspberrypi.lib.inject-overlays
          trusted-nix-caches
          nixpkgs-rpi
          # NOTE: `inject-overlays-global` is deliberately NOT imported. It
          # swaps ffmpeg/libcamera in the *global* package set to get the
          # RPi-tuned kodi, but that re-hashes everything downstream of them
          # (pipewire, gtk4, ... ) into packages no binary cache has, so the
          # Pi compiles them from source -- hours, on a Pi 400. Upstream says
          # so themselves in lib/default.nix: "!!! causes _lots_ of rebuilds
          # for graphical stuff via ffmpeg, pipewire". We get the tuned Kodi
          # from their prebuilt package instead (kodiLauncher.package below),
          # which is self-contained and fully cached.
        ];
        inherit hostname;
        system.stateVersion = "25.05"; # Do not change this !
      }
      {
        # WORKAROUND: nixos-raspberrypi's `overlays/vendor-firmware.nix`
        # defines `raspberrypiWirelessFirmware_20260321 =
        # prev.raspberrypiWirelessFirmware.overrideAttrs (...)`, but
        # `overlays/linux-and-firmware.nix` aliases the unversioned
        # `raspberrypiWirelessFirmware` -- what `hardware.firmware` on aarch64
        # actually consumes, via nixpkgs' `all-firmware.nix`, once
        # `hardware.enableRedistributableFirmware` (set unconditionally by
        # nixos-raspberrypi's own base module) is on -- to
        # `final.linuxAndFirmware.default`, which currently resolves to that
        # exact `_20260321` package. So `prev.raspberrypiWirelessFirmware` IS
        # `_20260321` by the time it's forced: a genuine self-reference
        # upstream (confirmed via `nix eval --show-trace`, reproduces
        # identically off-Pi). Every numbered variant in that file shares the
        # same poisoned `prev`, so there's no reachable non-cyclic value under
        # any of these names once nixos-raspberrypi's overlays are applied.
        # This reconstructs the package directly (mirroring nixpkgs'
        # `pkgs/by-name/ra/raspberrypiWirelessFirmware/package.nix`) using the
        # same srcs nixos-raspberrypi's `_20260321` override wanted,
        # sidestepping the cycle. Must come after inject-overlays-global above
        # (list-option order = overlay composition order) so this wins.
        nixpkgs.overlays = [
          (final: prev: {
            raspberrypiWirelessFirmware = prev.stdenvNoCC.mkDerivation {
              pname = "raspberrypi-wireless-firmware";
              version = "2026-03-21";
              srcs = [
                (prev.fetchFromGitHub {
                  name = "bluez-firmware";
                  owner = "RPi-Distro";
                  repo = "bluez-firmware";
                  rev = "cdf61dc691a49ff01a124752bd04194907f0f9cd";
                  hash = "sha256-35pnbQV/zcikz9Vic+2a1QAS72riruKklV8JHboL9NY=";
                })
                (prev.fetchFromGitHub {
                  name = "firmware-nonfree";
                  owner = "RPi-Distro";
                  repo = "firmware-nonfree";
                  rev = "9794282eb9f4a2de1f23b41a738926740e975d83";
                  hash = "sha256-OtA8yHvfusGP/ucf8Exzi+nSUmNoYp10u+luC2gbNZc=";
                })
              ];
              sourceRoot = ".";
              dontBuild = true;
              # Firmware blobs do not need fixing and should not be modified
              dontFixup = true;
              installPhase = ''
                runHook preInstall
                mkdir -p "$out/lib/firmware/brcm"

                # Wifi firmware
                cp -rv "$NIX_BUILD_TOP/firmware-nonfree/debian/config/brcm80211/." "$out/lib/firmware/"

                # Bluetooth firmware
                cp -rv "$NIX_BUILD_TOP/bluez-firmware/debian/firmware/broadcom/." "$out/lib/firmware/brcm"

                # brcmfmac43455-sdio.bin is a symlink to the non-existent path: ../cypress/cyfmac43455-sdio.bin.
                # See https://github.com/RPi-Distro/firmware-nonfree/issues/26
                ln -s "./cyfmac43455-sdio-standard.bin" "$out/lib/firmware/cypress/cyfmac43455-sdio.bin"

                pushd $out/lib/firmware/brcm &>/dev/null
                # Symlinks for Zero 2W
                ln -s "./brcmfmac43436-sdio.clm_blob" "$out/lib/firmware/brcm/brcmfmac43430b0-sdio.clm_blob"
                popd &>/dev/null

                runHook postInstall
              '';
              meta = {
                description = "Firmware for builtin Wifi/Bluetooth devices in the Raspberry Pi 3+ and Zero W";
                homepage = "https://github.com/RPi-Distro/firmware-nonfree";
                license = prev.lib.licenses.unfreeRedistributableFirmware;
                platforms = prev.lib.platforms.linux;
                sourceProvenance = with prev.lib.sourceTypes; [ binaryFirmware ];
              };
            };
            raspberrypiWirelessFirmware_20260321 = final.raspberrypiWirelessFirmware;
          })
        ];
      }
      ./_users
      ./_hardware-configuration.nix
      {
        modules = {
          profiles.rpi.enable = true;
          gaming.retroarch.enable = true;
          # RPi-tuned Kodi, taken prebuilt from nixos-raspberrypi's cachix
          # rather than rebuilt locally via inject-overlays-global (see the
          # note in the imports above, and the `package` option's docs).
          # Verified: `nix build --dry-run` on this package resolves to
          # 0 derivations built, 357 paths fetched.
          gaming.kodiLauncher.package =
            inputs.nixos-raspberrypi-pkgs.packages.aarch64-linux.kodi-gbm;
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
