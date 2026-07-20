{ inputs, ... }:
{
  # Shared across the gaming modules (retroarch, kiosk, emulationstation):
  # an un-optimized nixpkgs instance for the given system, so RetroArch/cage/
  # ES-DE and their large dependency trees (ffmpeg, SDL, Qt, ...) fetch
  # prebuilt from cache.nixos.org instead of recompiling against
  # nixos-raspberrypi's ARM-optimized stdenv, whose variants aren't in any
  # binary cache and would build from source on the Pi.
  flake.lib.mkStockPkgs =
    system:
    import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true; # some libretro cores (e.g. snes9x) are unfree
    };
}
