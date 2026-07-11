{
  flake.modules.nixos.retroarch =
    {
      config,
      lib,
      pkgs,
      inputs,
      ...
    }:
    let
      cfg = config.modules.gaming.retroarch;

      # Un-optimized nixpkgs. RetroArch + cores (and their large dependency trees:
      # ffmpeg, SDL, ...) come from here so they fetch prebuilt from cache.nixos.org,
      # instead of recompiling against nixos-raspberrypi's ARM-optimized stdenv —
      # whose variants aren't in any binary cache, so they'd build from source on the
      # Pi (~400 pkgs, infeasible on a Pi 400).
      pkgsStock = import inputs.nixpkgs {
        inherit (pkgs.stdenv.hostPlatform) system;
        config.allowUnfree = true; # some libretro cores (e.g. snes9x) are unfree
      };

      # Curated libretro core set. Adjust to taste — verify names against
      # `nix search nixpkgs libretro` (a wrong attr is an eval error).
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
          ++ lib.optional (cfg.colorTheme != null) ''ozone_menu_color_theme = "${toString cfg.colorTheme}"''
          ++ lib.optionals cfg.retroachievements.enable [
            ''cheevos_enable = "true"''
            ''cheevos_username = "${cfg.retroachievements.username}"''
          ]
        )
      );
      hasOverrides =
        cfg.saveDir != null
        || cfg.stateDir != null
        || cfg.colorTheme != null
        || cfg.retroachievements.enable;
      appendConfigPaths =
        lib.optional hasOverrides "${overrideCfg}"
        ++ cfg.extraAppendConfigs;
      appendFlag = lib.optionalString (appendConfigPaths != [ ]) (
        # RetroArch delimits multiple --appendconfig files with '|' (NOT ','). The
        # value MUST be shell-quoted: unquoted, the '|' is parsed as a shell pipe,
        # so only the first overlay reaches RetroArch and the rest are run as
        # commands ("Permission denied"). Quoting passes the whole list literally.
        " --appendconfig \"${lib.concatStringsSep "|" appendConfigPaths}\""
      );

      # RetroArch launch script (no display-mode logic — the shared kiosk module
      # forces the mode via wlr-randr before running this). Exposed as `kioskScript`
      # so the Pegasus launcher can reference it as a collection entry.
      launchScript = pkgs.writeShellScript "retroarch-launch" ''
        exec ${lib.getExe retroarch}${appendFlag}
      '';
    in
    {
      options.modules.gaming.retroarch = {
        enable = lib.mkEnableOption "Enable RetroArch emulation";

        user = lib.mkOption {
          type = lib.types.str;
          default = "guest";
          description = "User RetroArch runs as in the kiosk.";
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

        retroachievements = {
          enable = lib.mkEnableOption "RetroAchievements integration";
          username = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "RetroAchievements account username.";
          };
        };

        colorTheme = lib.mkOption {
          type = lib.types.nullOr lib.types.int;
          default = null;
          example = 2;
          description = ''
            Ozone menu color theme index. Common values:
              0 = Default (dark), 1 = Basic White, 2 = Dracula (purple),
              3 = Nord, 4 = Gruvbox Dark, 5 = Boysenberry.
            Null leaves the setting at RetroArch's default.
          '';
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

        kioskScript = lib.mkOption {
          type = lib.types.package;
          internal = true;
          description = ''
            The script that launches RetroArch (with all --appendconfig overlays).
            Exposed so the Pegasus launcher module can reference it as a collection
            entry without duplicating the logic.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ retroarch ];

        # Expose the launch script for the Pegasus module's RetroArch entry.
        modules.gaming.retroarch.kioskScript = launchScript;

        # Drive the shared kiosk with RetroArch by default. mkDefault so the Pegasus
        # module can take over `program` (and the kiosk `user`) when enabled.
        modules.gaming.kiosk = {
          enable = lib.mkDefault true;
          user = lib.mkDefault cfg.user;
          program = lib.mkDefault launchScript;
        };

        # ROM dir (+ save/state dirs), owned by the kiosk user so the sync job can
        # populate them and RetroArch can read/write them.
        systemd.tmpfiles.rules = [
          "d ${cfg.romDir} 0775 ${cfg.user} users - -"
        ]
        ++ lib.optional (cfg.saveDir != null) "d ${cfg.saveDir} 0775 ${cfg.user} users - -"
        ++ lib.optional (cfg.stateDir != null) "d ${cfg.stateDir} 0775 ${cfg.user} users - -";
      };
    };
}
