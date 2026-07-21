{
  flake.modules.nixos.kodiLauncher =
    {
      config,
      lib,
      pkgs,
      self,
      ...
    }:
    let
      cfg = config.modules.gaming.kodiLauncher;
      retroCfg = config.modules.gaming.retroarch;

      # kodi-wayland comes from the ambient pkgs (RPi-optimized via
      # nixos-raspberrypi's inject-overlays-global, see hosts/nixberry), not
      # pkgsStock -- unlike retroarch/cage, which need stock nixpkgs to avoid
      # an uncached ARM rebuild.
      pkgsStock = self.lib.mkStockPkgs pkgs.stdenv.hostPlatform.system;

      slugify = name: builtins.replaceStrings [ " " ] [ "-" ] (lib.toLower name);

      # Kodi's own GBM/DRM session stays on VT1 the whole time (it pauses on
      # VT deactivation, resumes on reactivation -- standard kernel VT_PROCESS
      # behaviour, not something we have to implement). A Favourite hands off
      # by switching to VT2, running the target there in a fresh cage session,
      # then switching back.
      mkHandoff =
        {
          slug,
          command,
        }:
        pkgs.writeShellScript "kodi-handoff-${slug}" ''
          /run/wrappers/bin/chvt 2
          ${command}
          /run/wrappers/bin/chvt 1
        '';

      retroarchHandoff = lib.optional retroCfg.enable {
        slug = "retroarch";
        fullname = "RetroArch";
        script = mkHandoff {
          slug = "retroarch";
          command = "${lib.getExe pkgsStock.cage} -- ${retroCfg.kioskScript}";
        };
      };

      appHandoffs = map (app: {
        slug = slugify app.name;
        fullname = app.name;
        script = mkHandoff {
          slug = slugify app.name;
          command = app.command;
        };
      }) cfg.apps;

      allHandoffs = retroarchHandoff ++ appHandoffs;

      favouriteEntry = h: ''
        <favourite name="${h.fullname}" thumb="">System.Exec("${h.script}")</favourite>
      '';

      favouritesXml = pkgs.writeText "favourites.xml" ''
        <favourites>
        ${lib.concatMapStrings favouriteEntry allHandoffs}
        </favourites>
      '';

      # kodi-wayland can never get GLES: nixpkgs hardcodes
      # `-DAPP_RENDER_SYSTEM=${if gbmSupport then "gles" else "gl"}` --
      # tied to gbmSupport, not waylandSupport, and not exposed as any
      # separate override. The v3d driver is GLES-only hardware (this is
      # also what LibreELEC, the proven Kodi-on-Pi reference, uses), so
      # kodi-wayland's desktop-GL build only ever got far enough to pass
      # Kodi's shader-loading checks via Mesa's compat-profile emulation,
      # not to actually render content (black screen despite an active
      # render loop). kodi-gbm already sets gbmSupport = true and needs no
      # override -- but it talks to DRM/KMS directly, so it can't run as a
      # Wayland client inside cage; it needs to own tty1's DRM master
      # itself, same as the EGLFS approach this replaces.
      kodiGbm = pkgs.kodi-gbm;

      launchScript = pkgs.writeShellScript "kodi-standalone-launch" ''
        exec ${kodiGbm}/bin/kodi-standalone
      '';
    in
    {
      options.modules.gaming.kodiLauncher = {
        enable = lib.mkEnableOption "Kodi kiosk launcher";

        user = lib.mkOption {
          type = lib.types.str;
          default = "guest";
          description = "User Kodi runs as. Should match retroarch.user.";
        };

        apps = lib.mkOption {
          type = lib.types.listOf (
            lib.types.submodule {
              options = {
                name = lib.mkOption {
                  type = lib.types.str;
                  description = "Display name shown as a Kodi Favourite.";
                };
                command = lib.mkOption {
                  type = lib.types.str;
                  description = "Shell command executed when this Favourite is selected.";
                };
              };
            }
          );
          default = [ ];
          description = "Extra apps to show as Kodi Favourites alongside RetroArch.";
          example = [
            {
              name = "Some App";
              command = "some-app --flag";
            }
          ];
        };
      };

      config = lib.mkIf cfg.enable {
        systemd.tmpfiles.rules = [
          "d /home/${cfg.user}/.kodi/userdata 0755 ${cfg.user} users - -"
          # Kodi doesn't create this itself on first run -- it tries to open
          # temp/kodi.log for writing before that point and aborts if missing.
          "d /home/${cfg.user}/.kodi/temp 0755 ${cfg.user} users - -"
          "L+ /home/${cfg.user}/.kodi/userdata/favourites.xml - - - - ${favouritesXml}"
        ];

        # kodi-gbm owns tty1's DRM master directly (see kodiGbm above) --
        # it does NOT run inside cage. Force the shared kiosk off so
        # cage-tty1.service doesn't also try to claim tty1.
        modules.gaming.kiosk.enable = lib.mkForce false;

        # `chvt` needs CAP_SYS_TTY_CONFIG; guest has none. Duplicated here
        # (rather than relying on kiosk.nix's copy) because kiosk is forced
        # off above -- used by mkHandoff's VT switch to/from RetroArch.
        security.wrappers.chvt = {
          source = "${pkgs.kbd}/bin/chvt";
          capabilities = "cap_sys_tty_config+ep";
          owner = "root";
          group = "root";
          permissions = "u+rx,g+x,o+x";
        };

        # Mirrors nixpkgs' services.cage module (and this repo's earlier
        # EGLFS/Pegasus attempt) -- the known-working pattern for a
        # kiosk-on-tty1 systemd unit that gets DRM access via a logind
        # session, just running kodi-standalone directly instead of
        # `cage -- <program>`.
        security.polkit.enable = true;
        security.pam.services.kodi.text = ''
          auth    required pam_unix.so nullok
          account required pam_unix.so
          session required pam_unix.so
          session required pam_env.so conffile=/etc/pam/environment readenv=0
          session required ${config.systemd.package}/lib/security/pam_systemd.so
        '';
        hardware.graphics.enable = lib.mkDefault true;
        systemd.defaultUnit = "graphical.target";
        systemd.targets.graphical.wants = [ "kodi-tty1.service" ];
        systemd.services.kodi-tty1 = {
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
            PAMName = "kodi";
          };
        };
      };
    };
}
