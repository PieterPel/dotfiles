# Ships this host's systemd journal to a Loki push endpoint, so its logs land in
# the same Grafana as everything else and a loki alert rule can see them
# (unit-level rules match on the `unit` label built here).
{ lib, ... }:
{
  flake.modules.nixos.alloy =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.modules.monitoring.alloy;
      secretKey = "loki-auth/password";
      templateName = "loki-auth-password";
      withAuth = cfg.passwordSopsFile != null;

      alloyConfig = pkgs.writeText "alloy.config" ''
        loki.relabel "journal_relabel" {
          forward_to = []

          rule {
            source_labels = ["__journal__systemd_unit"]
            target_label  = "unit"
          }

          rule {
            source_labels = ["__journal_priority_keyword"]
            target_label  = "level"
          }

          // Systemd lifecycle messages (e.g. "foo.service: Main process exited")
          // come from systemd itself with no _SYSTEMD_UNIT set; extract the service
          // name from the body so these events land under the right unit label.
          rule {
            source_labels = ["unit", "__journal_message"]
            separator     = ";"
            regex         = ";([a-zA-Z0-9_.@/-]+\\.(?:service|timer|socket)): .+"
            target_label  = "unit"
            replacement   = "$1"
          }
        }

        loki.source.journal "read" {
          max_age       = "12h"
          labels        = { "job" = "systemd-journal", "host" = "${config.networking.hostName}" }
          relabel_rules = loki.relabel.journal_relabel.rules
          forward_to    = [loki.write.central.receiver]
        }

        ${
          lib.optionalString withAuth ''
            // The sops-rendered password file, read once at startup; is_secret keeps
            // it out of Alloy's own UI and logs.
            local.file "loki_password" {
              filename  = "${config.sops.templates.${templateName}.path}"
              is_secret = true
            }
          ''
        }

        loki.write "central" {
          endpoint {
            url = "${cfg.url}"
            ${
              lib.optionalString withAuth ''
                basic_auth {
                  username = "${cfg.username}"
                  password = local.file.loki_password.content
                }
              ''
            }
          }
        }
      '';
    in
    {
      options.modules.monitoring.alloy = {
        enable = lib.mkEnableOption "ship the systemd journal to a Loki push endpoint";

        url = lib.mkOption {
          type = lib.types.str;
          description = "Loki push endpoint, e.g. `https://logs.example.com:3100/loki/api/v1/push`.";
          example = "https://grafana.example.ts.net:3200/loki/api/v1/push";
        };

        username = lib.mkOption {
          type = lib.types.str;
          default = "loki";
          description = "Basic-auth user for the push endpoint.";
        };

        passwordSopsFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = ''
            sops file holding the push credential, under the key `loki-auth/password`.
            Leave null for an endpoint that needs no credentials.
          '';
        };
      };

      config = lib.mkIf cfg.enable (lib.mkMerge [
        {
          services.alloy = {
            enable = true;
            configPath = alloyConfig;
          };

          users.users.alloy = {
            isSystemUser = true;
            group = "alloy";
            extraGroups = [ "systemd-journal" ];
          };
          users.groups.alloy = { };
        }

        (lib.mkIf withAuth {
          sops.secrets.${secretKey}.sopsFile = cfg.passwordSopsFile;
          sops.templates.${templateName} = {
            content = config.sops.placeholder.${secretKey};
            owner = "alloy";
            mode = "0400";
          };
        })
      ]);
    };
}
