{
  flake.modules.nixos.sqlite-backup =
    { config, lib, pkgs, ... }:
    let
      cfg = config.modules.backup.sqlite;
      sqlite3 = lib.getExe' pkgs.sqlite "sqlite3";
    in
    {
      options.modules.backup.sqlite = lib.mkOption {
        type = lib.types.listOf (
          lib.types.submodule {
            options = {
              name = lib.mkOption {
                type = lib.types.str;
                description = "Name of the unit and of the directory kept under `root`.";
              };

              dbPath = lib.mkOption {
                type = lib.types.str;
                description = "Path of the live database.";
              };

              schedule = lib.mkOption {
                type = lib.types.str;
                default = "03:00";
                description = "systemd `OnCalendar` expression for the backup.";
              };

              root = lib.mkOption {
                type = lib.types.str;
                default = "/mnt/data/backups";
                description = "Directory the copies are written to.";
              };

              retentionDays = lib.mkOption {
                type = lib.types.ints.positive;
                default = 14;
                description = "Age at which a copy is deleted.";
              };
            };
          }
        );
        default = [ ];
        description = "SQLite databases to snapshot on a timer.";
      };

      config = lib.mkIf (cfg != [ ]) {
        systemd.services = lib.listToAttrs (
          map (
            b:
            lib.nameValuePair "backup-${b.name}" {
              description = "Local backup of ${b.name}'s SQLite database";
              # Explicit tool paths: a systemd service's default PATH on NixOS is
              # minimal, so anything else only works by accident.
              path = [
                pkgs.coreutils
                pkgs.gzip
                pkgs.findutils
              ];
              serviceConfig = {
                Type = "oneshot";
                # sqlite3's own `.backup` takes a consistent snapshot even while
                # the database is being written to; `cp` can catch it mid-write.
                ExecStart = pkgs.writeShellScript "backup-${b.name}" ''
                  set -euo pipefail
                  mkdir -p "${b.root}/${b.name}"
                  dest="${b.root}/${b.name}/${b.name}-$(date +%Y%m%d-%H%M%S).db"
                  ${sqlite3} "${b.dbPath}" ".backup '$dest'"
                  gzip "$dest"
                  find "${b.root}/${b.name}" -name '*.db.gz' -mtime "+${toString b.retentionDays}" -delete
                '';
              };
            }
          ) cfg
        );

        systemd.timers = lib.listToAttrs (
          map (b: lib.nameValuePair "backup-${b.name}" {
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnCalendar = b.schedule;
              Persistent = true;
            };
          }) cfg
        );
      };
    };
}
