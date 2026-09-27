{
  flake.modules.nixos.caddy =
    { config, lib, ... }:
    let
      cfg = config.modules.networking.caddy;
    in
    {
      options.modules.networking.caddy = {
        enable = lib.mkEnableOption "Caddy, with every site declared once";

        email = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "ACME account email.";
        };

        sites = lib.mkOption {
          type = lib.types.listOf (
            lib.types.submodule {
              options = {
                text = lib.mkOption {
                  type = lib.types.lines;
                  description = "The Caddyfile site block.";
                };

                port = lib.mkOption {
                  type = lib.types.port;
                  default = 443;
                  description = "TCP port the site is served on.";
                };

                why = lib.mkOption {
                  type = lib.types.str;
                  description = "What the port is for, as it appears in tailnet.openPorts.";
                };
              };
            }
          );
          default = [ ];
          description = "Caddyfile blocks, each carrying the tailnet port it needs.";
        };
      };

      config = lib.mkIf cfg.enable {
        services.caddy = {
          enable = true;
          inherit (cfg) email;
          extraConfig = lib.concatMapStrings (s: s.text) cfg.sites;
        };

        # Declaring a site here is what opens its port: this is the firewall
        # side of the same list the Caddyfile is rendered from.
        tailnet.openPorts.${config.networking.hostName} =
          builtins.listToAttrs (
            map (s: {
              name = toString s.port;
              value = s.why;
            }) cfg.sites
          )
          // {
            "80" = "Caddy's HTTP->HTTPS redirect";
          };

        # Two sites claiming one port would silently drop a firewall entry.
        assertions = [
          {
            assertion =
              builtins.length (lib.unique (map (s: s.port) cfg.sites)) == builtins.length cfg.sites;
            message = "modules/networking/caddy.nix: two sites declare the same port";
          }
        ];
      };
    };
}
