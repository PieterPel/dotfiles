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

      # kodi-wayland is one of the few packages nixos-raspberrypi specifically
      # optimizes and caches for this hardware, so it comes from the ambient
      # (RPi-optimized) pkgs, unlike retroarch/cage/ES-DE which need stock
      # nixpkgs to avoid an uncached ARM rebuild.
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

      # Mesa's v3d driver reports GL 3.1 (compat profile), but this kodi
      # package only ships shader sources for GLSL 1.20/1.50/4.00 -- nothing
      # for 3.1's corresponding 1.40, so Kodi can't find
      # gl_shader_frag_texture_lim.glsl and silently falls back to a "fixed
      # pipeline" mode GLES doesn't support at all (black screen). Force Mesa
      # to report a version that has a matching shader directory.
      launchScript = pkgs.writeShellScript "kodi-standalone-launch" ''
        export MESA_GL_VERSION_OVERRIDE=4.0COMPAT
        exec ${pkgs.kodi-wayland}/bin/kodi-standalone
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

        modules.gaming.kiosk = {
          enable = lib.mkDefault true;
          user = lib.mkDefault cfg.user;
          program = launchScript;
        };
      };
    };
}
