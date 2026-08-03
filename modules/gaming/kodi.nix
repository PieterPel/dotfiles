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

      # retroarch/cage need stock nixpkgs to avoid an uncached ARM rebuild.
      # (Kodi itself no longer comes from ambient pkgs at all -- see the
      # `package` option below.)
      pkgsStock = self.lib.mkStockPkgs pkgs.stdenv.hostPlatform.system;

      slugify = name: builtins.replaceStrings [ " " ] [ "-" ] (lib.toLower name);

      kioskCfg = config.modules.gaming.kiosk;

      # wlroots takes the display's *preferred* mode, which on a TV is
      # typically 4K -- and a Pi 4 can't clock 4K@60 without
      # hdmi_enable_4kp60, so it settles on 4K@30. That's a bad trade for
      # emulation: 30Hz doesn't divide 60/50Hz retro content cleanly, and the
      # Pi burns its GPU budget compositing 8.3 MPix to draw a 240p game.
      # Reuses the shared kiosk's mode/output (already set for this host)
      # instead of adding a second place to configure the display.
      forceMode = lib.optionalString (kioskCfg.mode != null) ''
        ${lib.getExe pkgsStock.wlr-randr} --output ${kioskCfg.output} --mode ${kioskCfg.mode} || true
      '';

      # A Favourite starts a systemd unit; it must NOT run the target as a
      # child of Kodi. Both of these were verified on the box:
      #
      #  * A `System.Exec` child inherits Kodi's logind session, which is
      #    bound to VT1 (`loginctl`: it is the only seat0 session, VTNr=1).
      #    Switching VT away marks that session inactive, logind revokes its
      #    device access, and the child dies instantly. A unit with PAMName +
      #    TTYPath gets a session of its own instead.
      #  * Kodi opens /dev/dri/card0 directly rather than through logind, so
      #    logind cannot take DRM master away from it on a VT switch. cage
      #    then fails with "Could not take device: Device or resource busy"
      #    even from a correct, *active* session on another VT. So Kodi has to
      #    genuinely stop for the GPU to be free -- hence `conflicts`, with
      #    ExecStopPost bringing it back when the target exits. A pleasant
      #    consequence: no VT switching is involved at all.
      handoffUnit = h: "kodi-handoff-${h.slug}";

      mkHandoffService = h: {
        conflicts = [ "kodi-tty1.service" ];
        restartIfChanged = false;
        unitConfig.ConditionPathExists = "/dev/tty1";
        serviceConfig = {
          ExecStart = h.command;
          # `+` runs this with full privileges regardless of User=, so
          # bringing Kodi back needs no polkit rule of its own.
          #
          # --no-block is load-bearing, not a nicety: a plain `systemctl
          # start` waits for the job to finish, and starting kodi-tty1
          # requires stopping *this* unit (they conflict) -- which cannot
          # finish while its own ExecStopPost is still running. That deadlocks
          # until systemd's stop-post timeout fires and fails the unit, which
          # in turn fails the whole nixos-rebuild switch. Queue it instead.
          ExecStopPost = "+${config.systemd.package}/bin/systemctl start --no-block kodi-tty1.service";
          User = cfg.user;
          PAMName = "kodi";
          TTYPath = "/dev/tty1";
          TTYReset = "yes";
          TTYVHangup = "yes";
          TTYVTDisallocate = "yes";
          StandardInput = "tty-fail";
          StandardOutput = "journal";
          StandardError = "journal";
          IgnoreSIGPIPE = "no";
          UtmpIdentifier = "%n";
          UtmpMode = "user";
        };
      };

      mkHandoffLauncher =
        h:
        pkgs.writeShellScript "kodi-handoff-${h.slug}" ''
          exec ${config.systemd.package}/bin/systemctl start ${handoffUnit h}.service
        '';

      handoffServices = lib.listToAttrs (
        map (h: lib.nameValuePair (handoffUnit h) (mkHandoffService h)) allHandoffs
      );

      retroarchHandoff = lib.optional retroCfg.enable {
        slug = "retroarch";
        fullname = "RetroArch";
        # RetroArch ships its logo as SVG only, which Kodi cannot render.
        icon = self.lib.svgToPng pkgs {
          name = "retroarch-icon";
          src = "${pkgsStock.retroarch}/share/icons/hicolor/scalable/apps/com.libretro.RetroArch.svg";
        };
        command = "${lib.getExe pkgsStock.cage} -- ${
          pkgs.writeShellScript "kodi-retroarch-kiosk" ''
            ${forceMode}
            exec ${retroCfg.kioskScript}
          ''
        }";
      };

      appHandoffs = map (app: {
        slug = slugify app.name;
        fullname = app.name;
        inherit (app) command icon;
      }) cfg.apps;

      allHandoffs = retroarchHandoff ++ appHandoffs;

      # An empty thumb is what makes Kodi fall back to the generic star, so
      # only emit the attribute when there is actually an image. Kodi's image
      # loader does not render SVG, so these must be raster files.
      favouriteEntry = h: ''
        <favourite name="${h.fullname}"${
          lib.optionalString (h.icon != null) " thumb=\"${toString h.icon}\""
        }>System.Exec("${mkHandoffLauncher h}")</favourite>
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
      kodiGbm = cfg.package;

      launchScript = pkgs.writeShellScript "kodi-standalone-launch" ''
        exec ${kodiGbm}/bin/kodi-standalone
      '';
    in
    {
      options.modules.gaming.kodiLauncher = {
        enable = lib.mkEnableOption "Kodi kiosk launcher";

        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.kodi-gbm;
          defaultText = lib.literalExpression "pkgs.kodi-gbm";
          description = ''
            The kodi-gbm package to run. Must be a GBM build (gbmSupport =
            true), which is what forces APP_RENDER_SYSTEM=gles -- see the
            note above kodiGbm.

            Set this explicitly to a package from a flake whose binary cache
            actually has it prebuilt. Pulling nixos-raspberrypi's RPi-tuned
            kodi in via their `inject-overlays-global` instead looks
            equivalent but is not: that overlay replaces ffmpeg/libcamera for
            the *entire* package set, so everything downstream of them
            (pipewire, gtk4, ...) gets a hash no cache has, and the Pi then
            compiles all of it. Upstream flags this themselves in
            lib/default.nix: "!!! causes _lots_ of rebuilds for graphical
            stuff via ffmpeg, pipewire".
          '';
        };

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
                icon = lib.mkOption {
                  type = lib.types.nullOr lib.types.path;
                  default = null;
                  description = ''
                    Image shown as the Favourite's thumbnail. Kodi falls back
                    to a generic star when unset. Must be a raster format --
                    Kodi's image loader does not render SVG, so convert first
                    (e.g. with `rsvg-convert`) if all you have is vector art.
                  '';
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

      config = lib.mkIf cfg.enable (lib.mkMerge [
        # Handoff targets (RetroArch, plus anything in `apps`) each get their
        # own unit -- see the note above mkHandoffService for why running them
        # as a child of Kodi cannot work. Kept as a separate mkMerge member
        # because the block below defines systemd.services.kodi-tty1, and a
        # single attrset cannot define both that and `systemd.services`.
        { systemd.services = handoffServices; }
        {
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

        # Kodi runs as an unprivileged user, so starting a handoff unit needs
        # authorisation. Scoped to exactly the handoff units by name -- not
        # blanket manage-units rights.
        security.polkit.extraConfig = lib.mkIf (allHandoffs != [ ]) ''
          polkit.addRule(function(action, subject) {
            if (action.id == "org.freedesktop.systemd1.manage-units" &&
                subject.user == "${cfg.user}") {
              var handoffUnits = ${builtins.toJSON (map (h: "${handoffUnit h}.service") allHandoffs)};
              if (handoffUnits.indexOf(action.lookup("unit")) !== -1) {
                return polkit.Result.YES;
              }
            }
          });
        '';

        # `chvt` needs CAP_SYS_TTY_CONFIG; guest has none. Duplicated here
        # (rather than relying on kiosk.nix's copy) because kiosk is forced
        # off above. The handoff no longer switches VTs, but leaving this in
        # place keeps a manual escape hatch to a console.
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
        }
      ]);
    };
}
