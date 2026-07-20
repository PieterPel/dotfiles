{
  flake.modules.nixos.emulationstation =
    {
      config,
      lib,
      pkgs,
      self,
      ...
    }:
    let
      cfg = config.modules.gaming.emulationstation;
      retroCfg = config.modules.gaming.retroarch;

      pkgsStock = self.lib.mkStockPkgs pkgs.stdenv.hostPlatform.system;

      romsDir = "/var/lib/emulationstation/roms";

      # ES-DE's systems are ROM-folder scanners, not arbitrary launch entries.
      # A system whose one discoverable "ROM" is the launch script itself --
      # <command>%ROM%</command> just execs whatever file it found -- is the
      # standard way to add a fixed, non-emulator entry (e.g. Kodi).
      slugify = name: builtins.replaceStrings [ " " ] [ "-" ] (lib.toLower name);

      mkAppScript = app: pkgs.writeShellScript "es-de-app-${slugify app.name}" app.command;

      retroarchEntry = lib.optional retroCfg.enable {
        slug = "retroarch";
        fullname = "RetroArch";
        script = pkgs.writeShellScript "es-de-retroarch" ''
          exec ${retroCfg.kioskScript}
        '';
      };

      appEntries = map (app: {
        slug = slugify app.name;
        fullname = app.name;
        script = mkAppScript app;
      }) cfg.apps;

      allEntries = retroarchEntry ++ appEntries;

      systemXmlEntry = e: ''
        <system>
          <name>${e.slug}</name>
          <fullname>${e.fullname}</fullname>
          <path>${romsDir}/${e.slug}</path>
          <extension>.sh</extension>
          <command>%ROM%</command>
          <platform>${e.slug}</platform>
          <theme>${e.slug}</theme>
        </system>
      '';

      systemsXml = pkgs.writeText "es_systems.xml" ''
        <?xml version="1.0"?>
        <systemList>
        ${lib.concatMapStrings systemXmlEntry allEntries}
        </systemList>
      '';

      # ES-DE's app data dir is fixed at ~/ES-DE, not XDG_CONFIG_HOME.
      launchScript = pkgs.writeShellScript "emulationstation-launch" ''
        export SDL_VIDEODRIVER=wayland
        exec ${lib.getExe pkgsStock.emulationstation-de}
      '';
    in
    {
      options.modules.gaming.emulationstation = {
        enable = lib.mkEnableOption "EmulationStation-DE kiosk launcher";

        user = lib.mkOption {
          type = lib.types.str;
          default = "guest";
          description = "User EmulationStation-DE runs as. Should match retroarch.user.";
        };

        apps = lib.mkOption {
          type = lib.types.listOf (
            lib.types.submodule {
              options = {
                name = lib.mkOption {
                  type = lib.types.str;
                  description = "Display name shown in ES-DE, and the system's slug/filename.";
                };
                command = lib.mkOption {
                  type = lib.types.str;
                  description = "Shell command executed when this entry is launched.";
                };
              };
            }
          );
          default = [ ];
          description = "Extra apps to show in ES-DE alongside RetroArch, each as its own system.";
          example = [
            {
              name = "Kodi";
              command = "kodi --standalone";
            }
          ];
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ pkgsStock.emulationstation-de ];

        systemd.tmpfiles.rules = [
          "d /home/${cfg.user}/ES-DE/custom_systems 0755 ${cfg.user} users - -"
          "L+ /home/${cfg.user}/ES-DE/custom_systems/es_systems.xml - - - - ${systemsXml}"
        ]
        ++ lib.concatMap (e: [
          "d ${romsDir}/${e.slug} 0755 ${cfg.user} users - -"
          "L+ ${romsDir}/${e.slug}/${e.slug}.sh - - - - ${e.script}"
        ]) allEntries;

        modules.gaming.kiosk = {
          enable = lib.mkDefault true;
          user = lib.mkDefault cfg.user;
          program = launchScript;
        };
      };
    };
}
