let
  mkModule =
    { config, lib, pkgs, ... }:
    let
      host = config.networking.hostName;
      declared = config.tailnet.openPorts;
      ports = declared.${host} or { };
    in
    {
      # `openPorts` is a NixOS option rather than a flake option: the flake that
      # declares a host has to be able to fill in its own slice, and a host
      # declared in an external flake cannot reach an option that only exists
      # inside one flake.
      options.tailnet.openPorts = lib.mkOption {
        type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
        default = { };
        example = {
          hostname."7777" = "Grafana";
          other-host."9100" = "node_exporter, scraped by the VM's Prometheus";
        };
        description = ''
          TCP ports that stay reachable over the tailnet, keyed by hostname and
          then by port number, with the reason each one is open. Each port is
          declared next to the service that listens on it; the value is what
          /etc/tailnet-open-ports shows on the box.
        '';
      };

      # A host is gated by declaring its own slice. No slice, no change.
      config = lib.mkIf (declared ? ${host}) {
        assertions = [
          {
            assertion = lib.all (port: builtins.match "[0-9]+" port != null) (lib.attrNames ports);
            message =
              "tailnet.openPorts.${host} keys must be decimal port numbers, got: "
              + lib.concatStringsSep ", " (lib.attrNames ports);
          }
        ];

        # tailscaled otherwise installs a `ts-input` chain that INPUT jumps to
        # before `nixos-fw`, accepting all tailnet traffic and leaving the ports
        # above advisory. The mode is a client preference and not a daemon flag,
        # so it is applied once the daemon answers.
        systemd.services.tailscale-netfilter-off = {
          description = "Make nixos-fw the gate for tailnet traffic";
          after = [ "tailscaled.service" ];
          wants = [ "tailscaled.service" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = pkgs.writeShellScript "tailscale-netfilter-off" ''
              for _ in $(seq 1 10); do
                ${config.services.tailscale.package}/bin/tailscale set --netfilter-mode=off && exit 0
                sleep 3
              done
              echo "tailscale set --netfilter-mode=off failed: nixos-fw is not the gate for tailnet traffic" >&2
              exit 1
            '';
          };
        };

        networking.firewall = {
          # Whatever trusted `tailscale0` is replaced by this host's slice. "lo"
          # has to stay (the firewall module's own default): Caddy reaches its
          # upstreams over loopback, Prometheus the exporters, Alloy Loki.
          trustedInterfaces = lib.mkForce [ "lo" ];

          interfaces."tailscale0".allowedTCPPorts = lib.mapAttrsToList (port: _: lib.toInt port) ports;
        };

        environment.etc."tailnet-open-ports".text = ''
          # Tailnet ports of ${host}, rendered from config.tailnet.openPorts.
          # Do not edit: each is declared next to the service that listens on it.
          ${lib.concatMapStrings (port: "${port}\t${ports.${port}}\n") (lib.attrNames ports)}
        '';
      };
    };
in
{
  flake.modules.nixos.tailnet = mkModule;
}
