{
  flake.modules.nixos.tailscale-cert =
    { config, lib, pkgs, ... }:
    let
      cfg = config.modules.system.tailscaleCert;
      certPath = "/etc/tailscale-cert.pem";
      keyPath = "/etc/tailscale-key.pem";
    in
    {
      options.modules.system.tailscaleCert = {
        enable = lib.mkEnableOption "daily renewal of the Tailscale TLS cert a web server serves";

        domain = lib.mkOption {
          type = lib.types.str;
          description = "The tailnet name the certificate is issued for.";
        };

        group = lib.mkOption {
          type = lib.types.str;
          default = "caddy";
          description = "Group that gets read access to the private key.";
        };

        reloadUnit = lib.mkOption {
          type = lib.types.str;
          default = "caddy.service";
          description = "Unit restarted after a renewal.";
        };
      };

      config = lib.mkIf cfg.enable {
        systemd.services.tailscale-cert = {
          description = "Renew the Tailscale TLS cert";
          after = [
            "tailscaled.service"
            "network-online.target"
          ];
          wants = [ "network-online.target" ];
          serviceConfig = {
            Type = "oneshot";
            # `tailscale cert` only re-fetches once <2/3 of the cert's lifetime
            # has elapsed, so a daily run is a cheap no-op until renewal is due.
            ExecStart = pkgs.writeShellScript "tailscale-cert-renew" ''
              set -euo pipefail
              ${pkgs.tailscale}/bin/tailscale cert \
                --cert-file ${certPath} \
                --key-file ${keyPath} \
                ${cfg.domain}
              chgrp ${cfg.group} ${certPath} ${keyPath}
              chmod 0644 ${certPath}
              chmod 0640 ${keyPath}
            '';
            ExecStartPost = "${pkgs.systemd}/bin/systemctl reload-or-restart ${cfg.reloadUnit}";
          };
        };

        systemd.timers.tailscale-cert = {
          description = "Renew the Tailscale TLS cert";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "daily";
            # Catch up on the next boot if the host was down when the timer was
            # due, rather than waiting a full day with an expired cert.
            Persistent = true;
            RandomizedDelaySec = "1h";
          };
        };
      };
    };
}
