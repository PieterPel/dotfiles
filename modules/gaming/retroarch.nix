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

      # Config overlays layered on top of retroarch.cfg via --appendconfig: appended
      # config takes precedence and is NOT written back, so it pins settings without
      # fighting RetroArch's own config_save_on_exit.
      #
      # The save/state overlay is a plain store file (non-secret). Additional overlays
      # come in via `extraAppendConfigs` as raw path strings — so the private layer
      # can point at a file rendered at runtime (e.g. a sops template holding the
      # cloud-sync WebDAV password) that must never land in the world-readable store.
      overrideCfg = pkgs.writeText "retroarch-overrides.cfg" (
        lib.concatStringsSep "\n" (
          lib.optional (cfg.saveDir != null) ''savefile_directory = "${cfg.saveDir}"''
          ++ lib.optional (cfg.stateDir != null) ''savestate_directory = "${cfg.stateDir}"''
        )
      );
      appendConfigPaths =
        lib.optional (cfg.saveDir != null || cfg.stateDir != null) "${overrideCfg}"
        ++ cfg.extraAppendConfigs;
      appendFlag = lib.optionalString (appendConfigPaths != [ ]) (
        " --appendconfig ${lib.concatStringsSep "," appendConfigPaths}"
      );

      # Kiosk entrypoint. When a mode is forced, set it via wlr-randr (which talks to
      # cage's wlr-output-management) before launching RetroArch — wlroots otherwise
      # picks the display's preferred mode (often 4K on a TV), which a Pi 400 can't
      # composite smoothly, and its refresh rate also throws off frame pacing. Also
      # carries the save/state overlay. Runs inside the cage session, so the
      # compositor socket already exists.
      useWrapper = cfg.kiosk.mode != null || appendFlag != "";
      kioskProgram =
        if !useWrapper then
          lib.getExe retroarch
        else
          pkgs.writeShellScript "retroarch-kiosk" ''
            ${lib.optionalString (
              cfg.kiosk.mode != null
            ) "${lib.getExe pkgsStock.wlr-randr} --output ${cfg.kiosk.output} --mode ${cfg.kiosk.mode} || true"}
            exec ${lib.getExe retroarch}${appendFlag}
          '';
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

        saveDir = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = ''
            If set, pin RetroArch's savefile_directory (battery/.srm saves) here.
            Pinning makes the location deterministic so the private layer can back
            it up (otherwise saves can land next to the ROMs, non-deterministically).
          '';
        };

        stateDir = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "If set, pin RetroArch's savestate_directory (.state snapshots) here.";
        };

        extraAppendConfigs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [ "/run/secrets/retroarch-cloud.cfg" ];
          description = ''
            Extra config files to layer on via RetroArch's `--appendconfig` (in
            addition to the save/state overlay). Given as raw path strings, not store
            paths, so a caller can point at a file rendered at runtime — e.g. a sops
            template holding cloud-sync WebDAV credentials — that must stay out of the
            world-readable Nix store.
          '';
        };

        kiosk = {
          enable = lib.mkEnableOption "Boot straight into the RetroArch UI (cage kiosk)" // {
            default = true;
          };

          output = lib.mkOption {
            type = lib.types.str;
            default = "HDMI-A-1";
            description = "wlr-randr output name that `mode` is applied to.";
          };

          mode = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "1920x1080@60";
            description = ''
              If set, force this wlr-randr mode on the kiosk output before launching
              RetroArch. wlroots otherwise picks the display's preferred mode (often
              4K), which a Pi 400 can't drive smoothly and whose refresh rate breaks
              RetroArch's frame pacing.
            '';
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
        ]
        ++ lib.optional (cfg.saveDir != null) "d ${cfg.saveDir} 0775 ${cfg.user} users - -"
        ++ lib.optional (cfg.stateDir != null) "d ${cfg.stateDir} 0775 ${cfg.user} users - -";

        # Kiosk: a minimal Wayland compositor (cage) that launches RetroArch
        # fullscreen on boot. RetroArch's own Ozone UI is the "easy UI".
        services.cage = lib.mkIf cfg.kiosk.enable {
          enable = true;
          user = cfg.user;
          package = pkgsStock.cage; # stock cage/wlroots -> fetched, not ARM-rebuilt
          program = kioskProgram;
        };
      };
    };
}
