{
  flake.modules.nixos.pegasus =
    {
      config,
      lib,
      pkgs,
      inputs,
      ...
    }:
    let
      cfg = config.modules.gaming.pegasus;
      retroCfg = config.modules.gaming.retroarch;

      # Same pkgsStock pattern as retroarch.nix: pull from stock nixpkgs so
      # pegasus-frontend fetches prebuilt binaries from cache.nixos.org rather than
      # recompiling against the ARM-optimized stdenv.
      pkgsStock = import inputs.nixpkgs {
        inherit (pkgs.stdenv.hostPlatform) system;
      };

      # Generate a tiny launch script in the Nix store for each extra app.
      # Unsets the XDG_*_HOME overrides pegasus-launch exports for itself
      # (below) before exec'ing — otherwise every launched app inherits them
      # and reads/writes its config under Pegasus's dirs instead of its own.
      mkAppScript =
        app:
        pkgs.writeShellScript "pegasus-app-${builtins.replaceStrings [ " " ] [ "-" ] (lib.toLower app.name)}" ''
          unset XDG_CONFIG_HOME XDG_DATA_HOME
          ${app.command}
        '';

      # Pegasus owns tty1/DRM directly via EGLFS (see launchScript below) — it
      # does NOT run inside cage. RetroArch still needs cage (bare DRM/KMS
      # crashes for it, per retroarch.nix), so launching it means handing the
      # display off to a second, temporary session on a different VT:
      #   1. chvt away from Pegasus's VT. Qt's EGLFS KMS backend has built-in
      #      VT-switch support and releases DRM master + pauses rendering when
      #      its VT is deactivated — this is the documented mechanism for
      #      exactly this handoff, not a hack.
      #   2. cage (on the new, now-active VT) acquires DRM master uncontested
      #      and runs RetroArch, applying the same wlr-randr mode force the
      #      shared kiosk module would have (Pegasus's own launch bypasses that
      #      module entirely, so it has to happen here instead).
      #   3. On exit, chvt back — Qt/EGLFS resumes automatically on
      #      reactivation.
      retroarchLaunch = pkgs.writeShellScript "pegasus-retroarch-launch" ''
        unset XDG_CONFIG_HOME XDG_DATA_HOME
        /run/wrappers/bin/chvt 2
        ${lib.getExe pkgsStock.cage} -- ${pkgs.writeShellScript "pegasus-retroarch-cage-session" ''
          ${lib.getExe pkgsStock.wlr-randr} --output ${config.modules.gaming.kiosk.output} --mode ${config.modules.gaming.kiosk.mode} || true
          exec ${retroCfg.kioskScript}
        ''}
        /run/wrappers/bin/chvt 1
      '';

      retroarchEntry = lib.optionalString retroCfg.enable ''

        game: RetroArch
        file: ${retroarchLaunch}
        launch: {file.path}
        description: Play your retro game collection
      '';

      extraEntries = lib.concatMapStrings (
        app:
        let
          script = mkAppScript app;
        in
        ''

          game: ${app.name}
          file: ${script}
          launch: {file.path}
          ${lib.optionalString (app.description != "") "description: ${app.description}"}
        ''
      ) cfg.apps;

      metadataFile = pkgs.writeText "pegasus-metadata.pegasus.txt" ''
        collection: Apps
        shortname: apps
        ${retroarchEntry}${extraEntries}
      '';

      # EGLFS (direct KMS/DRM, no separate Wayland compositor) rather than the
      # shared cage/Wayland kiosk path RetroArch uses. Per Pegasus's own Pi
      # setup docs, and confirmed on this hardware: running Pegasus as a
      # Wayland *client* under cage adds an extra compositing hop (Pegasus's
      # buffers -> cage's own wlroots scanout) that measurably worsens the
      # vc4 driver's known swiotlb/DMA-bounce-buffer exhaustion bug
      # (raspberrypi/linux#3416 — the GPU can only DMA within the first 1GiB,
      # everything above bounces through a small pool) under Pegasus's
      # continuously-animated Grid theme: black screen within ~3 minutes,
      # vs. ~5.5 hours of plain RetroArch at the old 64M swiotlb default.
      # EGLFS removes that extra hop entirely.
      launchScript = pkgs.writeShellScript "pegasus-launch" ''
        export XDG_CONFIG_HOME=/var/lib/pegasus/config
        export XDG_DATA_HOME=/var/lib/pegasus/data
        export QT_QPA_PLATFORM=eglfs
        # Pi4-class (incl. Pi 400) GPU driver quirks, per Pegasus's own docs:
        # KMS_ATOMIC avoids "Could not queue DRM page flip" errors; FORCE888
        # improves gradient banding.
        export QT_QPA_EGLFS_KMS_ATOMIC=1
        export QT_QPA_EGLFS_FORCE888=1
        exec ${lib.getExe pkgsStock.pegasus-frontend}
      '';
    in
    {
      options.modules.gaming.pegasus = {
        enable = lib.mkEnableOption "Pegasus Frontend kiosk launcher";

        user = lib.mkOption {
          type = lib.types.str;
          default = "guest";
          description = "User Pegasus runs as. Should match retroarch.user.";
        };

        apps = lib.mkOption {
          type = lib.types.listOf (
            lib.types.submodule {
              options = {
                name = lib.mkOption {
                  type = lib.types.str;
                  description = "Display name shown in Pegasus.";
                };
                description = lib.mkOption {
                  type = lib.types.str;
                  default = "";
                  description = "Short description shown in Pegasus (optional).";
                };
                command = lib.mkOption {
                  type = lib.types.str;
                  description = "Shell command executed when this entry is launched.";
                };
              };
            }
          );
          default = [ ];
          description = "Extra apps to show in Pegasus alongside RetroArch.";
          example = [
            {
              name = "Kodi";
              description = "Media centre";
              command = "kodi --standalone";
            }
          ];
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ pkgsStock.pegasus-frontend ];

        systemd.tmpfiles.rules = [
          # Game/app collection directory — contains the metadata file Pegasus reads.
          "d /var/lib/pegasus/apps 0755 ${cfg.user} users - -"
          # Config dir Pegasus writes its settings to (XDG_CONFIG_HOME override).
          "d /var/lib/pegasus/config/pegasus-frontend 0755 ${cfg.user} users - -"
          # Data dir for Pegasus cache / theme data (XDG_DATA_HOME override).
          "d /var/lib/pegasus/data 0755 ${cfg.user} users - -"
          # Always-current symlink to the Nix-generated metadata file.
          "L+ /var/lib/pegasus/apps/metadata.pegasus.txt - - - - ${metadataFile}"
          # game_dirs.txt (not settings.txt — there is no `game_dir` settings key;
          # Pegasus silently ignores it) tells Pegasus which directories to scan
          # for metadata.pegasus.txt collections: one absolute path per line.
          # f+ truncates and rewrites on each activation so it tracks rebuilds.
          "f+ /var/lib/pegasus/config/pegasus-frontend/game_dirs.txt 0644 ${cfg.user} users - /var/lib/pegasus/apps"
        ];

        # Pegasus does NOT join the shared cage/Wayland kiosk (see launchScript)
        # — force it off so cage-tty1.service doesn't also try to claim tty1.
        modules.gaming.kiosk.enable = lib.mkForce false;

        # `chvt` needs CAP_SYS_TTY_CONFIG; guest has none. A capability
        # wrapper grants it narrowly (just this one binary) rather than full
        # root via sudo — used by retroarchLaunch's VT handoff above.
        security.wrappers.chvt = {
          source = "${pkgs.kbd}/bin/chvt";
          capabilities = "cap_sys_tty_config+ep";
        };

        # Mirrors nixpkgs' services.cage module (nixos/modules/services/wayland/cage.nix)
        # almost exactly, since that's the known-working pattern for a
        # kiosk-on-tty1 systemd unit — just running pegasus-launch (EGLFS)
        # directly instead of `cage -- <program>`.
        security.polkit.enable = true;
        security.pam.services.pegasus.text = ''
          auth    required pam_unix.so nullok
          account required pam_unix.so
          session required pam_unix.so
          session required pam_env.so conffile=/etc/pam/environment readenv=0
          session required ${config.systemd.package}/lib/security/pam_systemd.so
        '';
        hardware.graphics.enable = lib.mkDefault true;
        systemd.defaultUnit = "graphical.target";
        systemd.targets.graphical.wants = [ "pegasus-tty1.service" ];
        systemd.services.pegasus-tty1 = {
          enable = true;
          after = [
            "systemd-user-sessions.service"
            "plymouth-start.service"
            "plymouth-quit.service"
            "systemd-logind.service"
            "getty@tty1.service"
          ];
          before = [ "graphical.target" ];
          wants = [
            "dbus.socket"
            "systemd-logind.service"
            "plymouth-quit.service"
          ];
          wantedBy = [ "graphical.target" ];
          conflicts = [ "getty@tty1.service" ];
          restartIfChanged = false;
          unitConfig.ConditionPathExists = "/dev/tty1";
          serviceConfig = {
            ExecStart = "${launchScript}";
            User = cfg.user;
            IgnoreSIGPIPE = "no";
            UtmpIdentifier = "%n";
            UtmpMode = "user";
            TTYPath = "/dev/tty1";
            TTYReset = "yes";
            TTYVHangup = "yes";
            TTYVTDisallocate = "yes";
            StandardInput = "tty-fail";
            StandardOutput = "journal";
            StandardError = "journal";
            PAMName = "pegasus";
          };
        };
      };
    };
}
