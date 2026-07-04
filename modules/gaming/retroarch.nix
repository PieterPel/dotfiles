{
  flake.modules.nixos.retroarch =
    { config, lib, pkgs, inputs, ... }:
    let
      cfg = config.modules.gaming.retroarch;

      # Un-optimized nixpkgs. RetroArch + cores + cage (and their large dependency
      # trees: ffmpeg, SDL, wlroots, ...) come from here so they fetch prebuilt from
      # cache.nixos.org, instead of recompiling against nixos-raspberrypi's
      # ARM-optimized stdenv — whose variants of these aren't in any binary cache, so
      # they'd build from source on the Pi (~400 pkgs, infeasible on a Pi 400).
      # Verified: stock retroarch+cores+cage = ~all fetched vs 414 built optimized.
      pkgsStock = import inputs.nixpkgs {
        inherit (pkgs.stdenv.hostPlatform) system;
        config.allowUnfree = true; # some libretro cores (e.g. snes9x) are unfree
      };

      # Curated libretro core set. Adjust to taste — verify names against
      # `nix search nixpkgs libretro` (a wrong attr is an eval error).
      # For an everything-included build, swap this for `pkgsStock.retroarchFull`.
      retroarch = pkgsStock.retroarch.withCores (
        cores: with cores; [
          snes9x # SNES
          nestopia # NES
          genesis-plus-gx # Genesis / Master System / Game Gear
          mgba # GB / GBC / GBA
          mupen64plus # N64
          pcsx-rearmed # PS1 (ARM-optimised)
          beetle-psx-hw # PS1 (accurate, HW-rendered)
          # fbneo (arcade) omitted for now: its stock aarch64 build isn't cached,
          # so it compiles on the Pi. Re-add once you want arcade + can wait on it.
        ]
      );
    in
    {
      options.modules.gaming.retroarch = {
        enable = lib.mkEnableOption "Enable RetroArch emulation";

        user = lib.mkOption {
          type = lib.types.str;
          default = "guest";
          description = "User RetroArch runs as in kiosk mode.";
        };

        romDir = lib.mkOption {
          type = lib.types.path;
          default = "/var/lib/roms";
          description = ''
            Directory RetroArch reads ROMs from. The private layer's sync job
            writes here; kept as an option so both sides agree on one path.
          '';
        };

        kiosk = {
          enable = lib.mkEnableOption "Boot straight into the RetroArch UI (cage kiosk)" // {
            default = true;
          };
        };
      };

      config = lib.mkIf cfg.enable {
        # GPU access for the libretro GL/GLES cores (v3d on the Pi).
        hardware.graphics.enable = true;

        environment.systemPackages = [ retroarch ];

        # ROM dir, owned by the kiosk user so the sync job can populate it
        # and RetroArch can read it.
        systemd.tmpfiles.rules = [
          "d ${cfg.romDir} 0775 ${cfg.user} users - -"
        ];

        # Kiosk: a minimal Wayland compositor (cage) that launches RetroArch
        # fullscreen on boot. RetroArch's own Ozone UI is the "easy UI".
        services.cage = lib.mkIf cfg.kiosk.enable {
          enable = true;
          user = cfg.user;
          package = pkgsStock.cage; # stock cage/wlroots -> fetched, not ARM-rebuilt
          program = "${retroarch}/bin/retroarch";
        };
      };
    };
}
