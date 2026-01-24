let
  module = "amp";
  parent = "terminal";
in
{
  flake.modules.homeManager.${module} =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.modules.${parent}.${module};
      settingsJson = builtins.toJSON { "amp.url" = cfg.url; };
      absPath =
        path:
        if lib.strings.hasPrefix "/" path then
          path
        else
          "${config.home.homeDirectory}/${path}";
      proxyConfigBase = {
        host = cfg.proxy.host;
        port = cfg.proxy.port;
        auth-dir = cfg.proxy.authDir;
        debug = cfg.proxy.debug;
        logging-to-file = cfg.proxy.loggingToFile;
        ampcode = {
          upstream-url = cfg.proxy.ampcodeUpstreamUrl;
          restrict-management-to-localhost = cfg.proxy.restrictManagementToLocalhost;
          model-mappings = cfg.proxy.modelMappings;
          force-model-mappings = cfg.proxy.forceModelMappings;
        };
      };
      proxyConfig =
        proxyConfigBase
        // lib.optionalAttrs (cfg.proxy.apiKeys != [ ]) {
          api-keys = cfg.proxy.apiKeys;
        }
        // lib.optionalAttrs (cfg.proxy.ampcodeUpstreamApiKey != null) {
          ampcode = proxyConfigBase.ampcode // {
            upstream-api-key = cfg.proxy.ampcodeUpstreamApiKey;
          };
        };
      proxyConfigYaml = lib.generators.toYAML { } proxyConfig;
    in
    {
      options.modules.${parent}.${module} = {
        enable = lib.mkEnableOption "Enable Amp CLI configuration.";
        url = lib.mkOption {
          type = lib.types.str;
          default = "http://localhost:8317";
          description = "Amp proxy URL.";
        };
        secretsFile = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Path to an existing Amp secrets.json to symlink.";
        };
        sops = {
          enable = lib.mkEnableOption "Manage Amp and CLIProxyAPI secrets via sops-nix.";
          sopsFile = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = "Sops file containing Amp and CLIProxyAPI secrets.";
          };
          clientApiKeyKey = lib.mkOption {
            type = lib.types.str;
            default = "amp-client-api-key";
            description = "Sops key for the CLIProxyAPI client API key.";
          };
          upstreamApiKeyKey = lib.mkOption {
            type = lib.types.str;
            default = "amp-upstream-api-key";
            description = "Sops key for the Amp upstream API key.";
          };
        };
        proxy = {
          enable = lib.mkEnableOption "Enable CLIProxyAPI config management for Amp.";
          configPath = lib.mkOption {
            type = lib.types.str;
            default = ".config/cli-proxy-api/config.yaml";
            description = "Target path for CLIProxyAPI config.yaml (relative to home).";
          };
          configFile = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Out-of-store CLIProxyAPI config.yaml to symlink (preferred for secrets).";
          };
          host = lib.mkOption {
            type = lib.types.str;
            default = "127.0.0.1";
            description = "CLIProxyAPI bind host.";
          };
          port = lib.mkOption {
            type = lib.types.int;
            default = 8317;
            description = "CLIProxyAPI port.";
          };
          authDir = lib.mkOption {
            type = lib.types.str;
            default = "${config.home.homeDirectory}/.cli-proxy-api";
            description = "CLIProxyAPI auth directory.";
          };
          debug = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable CLIProxyAPI debug mode.";
          };
          loggingToFile = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable CLIProxyAPI file logging.";
          };
          ampcodeUpstreamUrl = lib.mkOption {
            type = lib.types.str;
            default = "https://ampcode.com";
            description = "Amp upstream control plane URL.";
          };
          ampcodeUpstreamApiKey = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Amp upstream API key (stored in Nix store if set).";
          };
          forceModelMappings = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Force Amp model mappings to override local API keys.";
          };
          restrictManagementToLocalhost = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Restrict Amp management routes to localhost.";
          };
          modelMappings = lib.mkOption {
            type = lib.types.listOf lib.types.attrs;
            default = [ ];
            description = "Amp model mappings for CLIProxyAPI.";
          };
          apiKeys = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "CLIProxyAPI client API keys (stored in Nix store if set).";
          };
          package = lib.mkOption {
            type = lib.types.nullOr lib.types.package;
            default = null;
            description = "CLIProxyAPI package to install.";
          };
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = cfg.proxy.configFile == null || cfg.proxy.apiKeys == [ ];
            message = "Set either modules.terminal.amp.proxy.configFile or modules.terminal.amp.proxy.apiKeys, not both.";
          }
          {
            assertion = cfg.proxy.configFile == null || cfg.proxy.ampcodeUpstreamApiKey == null;
            message = "Set either modules.terminal.amp.proxy.configFile or modules.terminal.amp.proxy.ampcodeUpstreamApiKey, not both.";
          }
          {
            assertion = !cfg.sops.enable || cfg.secretsFile == null;
            message = "Set either modules.terminal.amp.secretsFile or modules.terminal.amp.sops.enable, not both.";
          }
          {
            assertion = !cfg.sops.enable || cfg.proxy.configFile == null;
            message = "Set either modules.terminal.amp.proxy.configFile or modules.terminal.amp.sops.enable, not both.";
          }
          {
            assertion = !cfg.sops.enable || (cfg.proxy.apiKeys == [ ] && cfg.proxy.ampcodeUpstreamApiKey == null);
            message = "When modules.terminal.amp.sops.enable is true, provide secrets via sops instead of proxy.apiKeys or proxy.ampcodeUpstreamApiKey.";
          }
          {
            assertion = !cfg.sops.enable || cfg.sops.sopsFile != null;
            message = "Set modules.terminal.amp.sops.sopsFile when modules.terminal.amp.sops.enable is true.";
          }
          {
            assertion = !cfg.sops.enable || config.modules.security.sops.enable;
            message = "Enable modules.security.sops when modules.terminal.amp.sops.enable is true.";
          }
        ];

        packages =
          [
            pkgs.amp-cli
          ]
          ++ lib.optional (cfg.proxy.package != null) cfg.proxy.package;

        home.file =
          {
            ".config/amp/settings.json".text = settingsJson;
          }
          // lib.optionalAttrs (cfg.secretsFile != null && !cfg.sops.enable) {
            ".local/share/amp/secrets.json".source =
              config.lib.file.mkOutOfStoreSymlink cfg.secretsFile;
          }
          // lib.optionalAttrs (cfg.proxy.enable && !cfg.sops.enable) (
            if cfg.proxy.configFile != null then
              {
                "${cfg.proxy.configPath}".source =
                  config.lib.file.mkOutOfStoreSymlink cfg.proxy.configFile;
              }
            else
              {
                "${cfg.proxy.configPath}".text = proxyConfigYaml;
              }
          );

        sops = lib.mkIf cfg.sops.enable {
          secrets = {
            "amp-client-api-key" = {
              sopsFile = cfg.sops.sopsFile;
              key = cfg.sops.clientApiKeyKey;
              path = "${config.xdg.configHome}/sops-nix/secrets/amp-client-api-key";
            };
            "amp-upstream-api-key" = {
              sopsFile = cfg.sops.sopsFile;
              key = cfg.sops.upstreamApiKeyKey;
              path = "${config.xdg.configHome}/sops-nix/secrets/amp-upstream-api-key";
            };
          };

          templates = {
            "amp-secrets.json" = {
              path = "${config.xdg.dataHome}/amp/secrets.json";
              content = builtins.toJSON {
                "apiKey@${cfg.url}" = config.sops.placeholder."amp-client-api-key";
                "apiKey@https://ampcode.com/" = config.sops.placeholder."amp-upstream-api-key";
              };
            };
          }
          // lib.optionalAttrs cfg.proxy.enable {
            "cli-proxy-api-config.yaml" = {
              path = absPath cfg.proxy.configPath;
              content =
                let
                  proxyConfigWithSecrets =
                    proxyConfigBase
                      // {
                      api-keys = [ config.sops.placeholder."amp-client-api-key" ];
                      ampcode = proxyConfigBase.ampcode // {
                        upstream-api-key = config.sops.placeholder."amp-upstream-api-key";
                      };
                    };
                in
                lib.generators.toYAML { } proxyConfigWithSecrets;
            };
          };
        };
      };
    };
}
