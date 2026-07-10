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
      mkAppScript =
        app:
        pkgs.writeShellScript "pegasus-app-${builtins.replaceStrings [ " " ] [ "-" ] (lib.toLower app.name)}" app.command;

      retroarchEntry = lib.optionalString retroCfg.enable ''

        game: RetroArch
        file: ${retroCfg.kioskScript}
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

      # Launch script (no display-mode logic — the shared kiosk module forces the
      # mode via wlr-randr before running this).
      launchScript = pkgs.writeShellScript "pegasus-launch" ''
        export XDG_CONFIG_HOME=/var/lib/pegasus/config
        export XDG_DATA_HOME=/var/lib/pegasus/data
        export QT_QPA_PLATFORM=wayland
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
          # Single-line settings file telling Pegasus where to find our apps collection.
          # f+ truncates and rewrites on each activation so it tracks rebuilds.
          "f+ /var/lib/pegasus/config/pegasus-frontend/settings.txt 0644 ${cfg.user} users - game_dir: /var/lib/pegasus/apps"
        ];

        # Take over the shared kiosk: a normal-priority `program` overrides the
        # RetroArch module's mkDefault, so Pegasus becomes the launched frontend.
        modules.gaming.kiosk = {
          enable = lib.mkDefault true;
          user = lib.mkDefault cfg.user;
          program = launchScript;
        };
      };
    };
}
