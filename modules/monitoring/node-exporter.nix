{
  flake.modules.nixos.node-exporter =
    { config, lib, ... }:
    let
      cfg = config.modules.monitoring.nodeExporter;
    in
    {
      options.modules.monitoring.nodeExporter = {
        enable = lib.mkEnableOption "node_exporter, scraped by a central Prometheus";

        port = lib.mkOption {
          type = lib.types.port;
          default = 9100;
          description = "Port node_exporter listens on, and the tailnet port declared for it.";
        };
      };

      config = lib.mkIf cfg.enable {
        # Declared rather than opened on every interface: the scrapers reach this
        # by MagicDNS name, so the port stays off whatever other network the host
        # is on (a home LAN, for instance).
        tailnet.openPorts.${config.networking.hostName}.${toString cfg.port} =
          "node_exporter, scraped by the central Prometheus";

        # hwmon is beyond the usual default set on purpose: a box that slows down
        # and then hangs has no CPU/memory/disk signature, so without a
        # temperature time series there is no way to rule thermal in or out
        # afterwards.
        services.prometheus.exporters.node = {
          enable = true;
          inherit (cfg) port;
          enabledCollectors = [
            "cpu"
            "diskstats"
            "filesystem"
            "hwmon"
            "loadavg"
            "meminfo"
            "netdev"
            "systemd"
            "time"
            "uname"
          ];
        };
      };
    };
}
