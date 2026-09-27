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
      (
        { pkgs, lib, ... }:
        {
          # The Bluetooth stack simply wasn't installed -- bluetooth.service
          # was `not-found`, even though the adapter (hci0), its firmware and
          # the kernel modules were all present and unblocked.
          hardware.bluetooth = {
            enable = true;
            powerOnBoot = true;
          };

          # No Bluetooth tile: pairing lives in the Kodi addon (see
          # kodiLauncher.package). A tile launching a TUI was useless from the
          # couch -- a gamepad emits joystick events and a TUI reads keys, so
          # the controller did nothing in it. Kodi routes joystick input into
          # its own UI, which is why the addon works and the tile didn't.
          #
          # Wi-Fi stays a TUI for now, so it needs the Pi 400's built-in
          # keyboard. impala drives iwd, the daemon already running here (from
          # nixos-raspberrypi's base config), so it manages the same state as
          # `iwctl`, including the PSKs under /var/lib/iwd. Replaceable by a
          # Kodi addon later: plugin.program.wifi drives nmcli, which would
          # mean running NetworkManager with iwd as its backend.
          modules.gaming.kodiLauncher.apps = [
            {
              name = "Wi-Fi";
              # cage supplies the compositor (and, through the handoff unit,
              # the GPU -- see kodi.nix); foot hosts the TUI.
              command = "${lib.getExe' pkgs.cage "cage"} -- ${lib.getExe' pkgs.foot "foot"} ${
                lib.getExe' pkgs.impala "impala"
              }";
            }
          ];
        }
      )
      ./_users
      ./_hardware-configuration.nix
      (
        { pkgs, ... }:
        {
        modules = {
          profiles.rpi.enable = true;
          gaming.retroarch.enable = true;
          # RPi-tuned Kodi, taken prebuilt from nixos-raspberrypi's cachix
          # rather than rebuilt locally via inject-overlays-global (see the
          # note in the imports above, and the `package` option's docs).
          # Verified: `nix build --dry-run` on this package resolves to
          # 0 derivations built, 357 paths fetched.
          # `.withPackages` adds binary addons without rebuilding Kodi -- the
          # package itself still substitutes; only the addon and its
          # kodi-platform helper build (both small). The base package ships
          # no binary addons at all (it has no lib/kodi/addons directory),
          # and Kodi cannot read joysticks without peripheral.joystick, so
          # without this a connected gamepad does nothing in the Kodi UI
          # even though the kernel exposes it fine as /dev/input/js0.
          gaming.kodiLauncher.package =
            inputs.nixos-raspberrypi-pkgs.packages.aarch64-linux.kodi-gbm.withPackages (
              p: [
                p.joystick

                # Bluetooth pairing from inside Kodi. This is the only place
                # it can live and still be usable from the couch: Kodi routes
                # joystick input into its own UI, so a controller can drive
                # it -- which a TUI like bluetuith fundamentally cannot
                # receive, since a gamepad emits joystick events, not keys.
                # It talks to bluez over D-Bus and implements Secure Simple
                # Pairing (confirmation / passkey / PIN), so each device is
                # confirmed on screen rather than leaving the adapter open to
                # anything in range.
                (p.buildKodiAddon {
                  pname = "bluetooth-manager";
                  namespace = "script.bluetooth.man";
                  version = "1.0.6";
                  src = pkgs.fetchFromGitHub {
                    owner = "wastis";
                    repo = "BluetoothManager";
                    # 1.0.6 is untagged -- the tag list stops at v1.0.5, but
                    # this commit's addon.xml declares 1.0.6 and carries the
                    # SSP handlers (RequestConfirmation / RequestPasskey /
                    # DisplayPinCode) that the older tags lack.
                    rev = "3d2a31727bedecbbaa1b3dcd606390b006b7ca3a";
                    hash = "sha256-hWNi2hm5FmkRPamxMSHF3WfQ+2V+qQzkkTJWuqazbAc=";
                  };
                })
              ]
            );
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
      )
    ];
  };
}
