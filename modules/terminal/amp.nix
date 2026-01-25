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
        oauth-model-alias = cfg.proxy.oauthModelAlias;
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
      proxyCommand =
        if cfg.proxy.package != null then
          [ (lib.getExe cfg.proxy.package) ]
        else if cfg.proxy.command != null then
          cfg.proxy.command
        else if lib.hasAttr "cli-proxy-api" pkgs then
          [ (lib.getExe pkgs.cli-proxy-api) ]
        else
          [ "cli-proxy-api" ];
      proxyArgs =
        proxyCommand
        ++ [
          "--config"
          (absPath cfg.proxy.configPath)
        ]
        ++ cfg.proxy.service.extraArgs;
      proxyLoginCommand =
        lib.concatStringsSep " " (
          map lib.escapeShellArg (
            proxyCommand ++ [
              "--config"
              (absPath cfg.proxy.configPath)
              "--login"
            ]
          )
        );
      proxyCodexLoginCommand =
        lib.concatStringsSep " " (
          map lib.escapeShellArg (
            proxyCommand ++ [
              "--config"
              (absPath cfg.proxy.configPath)
              "--codex-login"
            ]
          )
        );
      proxyClaudeLoginCommand =
        lib.concatStringsSep " " (
          map lib.escapeShellArg (
            proxyCommand ++ [
              "--config"
              (absPath cfg.proxy.configPath)
              "--claude-login"
            ]
          )
        );
      defaultServicePath =
        if pkgs.stdenv.isDarwin then
          [
            "/opt/homebrew/bin"
            "/usr/local/bin"
            "/usr/bin"
            "/bin"
            "/usr/sbin"
            "/sbin"
          ]
        else
          [
            "/usr/local/bin"
            "/usr/bin"
            "/bin"
            "/usr/sbin"
            "/sbin"
          ];
      proxyServicePath = if cfg.proxy.service.path != null then cfg.proxy.service.path else defaultServicePath;
      proxyServiceEnvironment =
        cfg.proxy.service.environment
        // lib.optionalAttrs (proxyServicePath != [ ]) {
          PATH = lib.concatStringsSep ":" proxyServicePath;
        };
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
          oauthModelAlias = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = { };
            description = "OAuth model aliases for CLIProxyAPI.";
          };
          apiKeys = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "CLIProxyAPI client API keys (stored in Nix store if set).";
          };
          command = lib.mkOption {
            type = lib.types.nullOr (lib.types.listOf lib.types.str);
            default = null;
            description = "CLIProxyAPI command to run when not using a Nix package (arguments appended automatically).";
          };
          package = lib.mkOption {
            type = lib.types.nullOr lib.types.package;
            default = null;
            description = "CLIProxyAPI package to install.";
          };
          service = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Run CLIProxyAPI as a user service.";
            };
            environment = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              default = { };
              description = "Extra environment variables for the CLIProxyAPI service.";
            };
            path = lib.mkOption {
              type = lib.types.nullOr (lib.types.listOf lib.types.str);
              default = null;
              description = "PATH entries for the CLIProxyAPI service.";
            };
            extraArgs = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Extra CLIProxyAPI command-line arguments.";
            };
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
          {
            assertion =
              !(cfg.proxy.enable && cfg.proxy.service.enable)
              || (cfg.proxy.package != null || cfg.proxy.command != null || lib.hasAttr "cli-proxy-api" pkgs);
            message = "Set modules.terminal.amp.proxy.package or modules.terminal.amp.proxy.command when enabling the CLIProxyAPI service.";
          }
        ];

        packages =
          [
            pkgs.amp-cli
          ]
          ++ lib.optional (cfg.proxy.package != null) cfg.proxy.package
          ++ lib.optional (cfg.proxy.package == null && lib.hasAttr "cli-proxy-api" pkgs) pkgs.cli-proxy-api;

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
          )
          // lib.optionalAttrs cfg.proxy.enable {
            ".local/bin/proxy" = {
              text = ''
                #!/usr/bin/env sh
                exec ${proxyLoginCommand}
              '';
              executable = true;
            };
            ".local/bin/proxy-codex" = {
              text = ''
                #!/usr/bin/env sh
                exec ${proxyCodexLoginCommand}
              '';
              executable = true;
            };
            ".local/bin/proxy-claude" = {
              text = ''
                #!/usr/bin/env sh
                exec ${proxyClaudeLoginCommand}
              '';
              executable = true;
            };
          };

        home.shellAliases = lib.mkIf cfg.proxy.enable {
          proxy = proxyLoginCommand;
          proxy-codex = proxyCodexLoginCommand;
          proxy-claude = proxyClaudeLoginCommand;
        };

        home.activation = lib.mkIf (cfg.proxy.enable && cfg.proxy.service.enable && pkgs.stdenv.isDarwin) {
          cliProxyApiLogs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            mkdir -p "$HOME/Library/Logs/CLIProxyAPI"
          '';
        };

        launchd.agents = lib.mkIf (cfg.proxy.enable && cfg.proxy.service.enable && pkgs.stdenv.isDarwin) {
          cli-proxy-api = {
            enable = true;
            config = {
              ProgramArguments = proxyArgs;
              KeepAlive = true;
              RunAtLoad = true;
              StandardOutPath = "${config.home.homeDirectory}/Library/Logs/CLIProxyAPI/stdout";
              StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/CLIProxyAPI/stderr";
              EnvironmentVariables = proxyServiceEnvironment;
            };
          };
        };

        systemd.user.services = lib.mkIf (cfg.proxy.enable && cfg.proxy.service.enable && pkgs.stdenv.isLinux) {
          cli-proxy-api = {
            Unit = {
              Description = "CLIProxyAPI";
              After = lib.optional cfg.sops.enable "sops-nix.service";
            };
            Service = {
              ExecStart =
                lib.concatStringsSep " " (
                  map lib.escapeShellArg proxyArgs
                );
              Environment = lib.mapAttrsToList (name: value: "${name}=${value}") proxyServiceEnvironment;
              Restart = "on-failure";
            };
            Install = {
              WantedBy = [ "default.target" ];
            };
          };
        };

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
              mode = "0600";
              content = builtins.toJSON {
                "apiKey@${cfg.url}" = config.sops.placeholder."amp-client-api-key";
                "apiKey@https://ampcode.com/" = config.sops.placeholder."amp-upstream-api-key";
              };
            };
          }
          // lib.optionalAttrs cfg.proxy.enable {
            "cli-proxy-api-config.yaml" = {
              path = absPath cfg.proxy.configPath;
              mode = "0600";
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
