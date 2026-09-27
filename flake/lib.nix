{ inputs, ... }:
{
  # Shared helpers. These live together in one module because flake-parts
  # treats `flake.lib` as a single value rather than merging it across
  # modules -- defining it in two files is a conflict, not a merge.
  flake.lib = {
    # Shared across the gaming modules (retroarch, kiosk, emulationstation):
    # an un-optimized nixpkgs instance for the given system, so RetroArch/cage/
    # ES-DE and their large dependency trees (ffmpeg, SDL, Qt, ...) fetch
    # prebuilt from cache.nixos.org instead of recompiling against
    # nixos-raspberrypi's ARM-optimized stdenv, whose variants aren't in any
    # binary cache and would build from source on the Pi.
    mkStockPkgs =
      system:
      import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true; # some libretro cores (e.g. snes9x) are unfree
      };

    # Rasterise vector art. Most packages ship their logo as SVG only, but
    # plenty of consumers can't render it -- Kodi's image loader, for one,
    # which silently falls back to a placeholder. librsvg is a build-time
    # input only, so the closure gains just the resulting PNG.
    svgToPng =
      pkgs:
      {
        name,
        src,
        size ? 256,
      }:
      pkgs.runCommand "${name}.png" { nativeBuildInputs = [ pkgs.librsvg ]; } ''
        rsvg-convert \
          --width=${toString size} --height=${toString size} \
          --keep-aspect-ratio \
          --output "$out" \
          ${src}
      '';
  };
}