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
        request-log = cfg.proxy.requestLog;
        oauth-model-alias = cfg.proxy.oauthModelAlias;
        ampcode = {
          upstream-url = cfg.proxy.ampcodeUpstreamUrl;
          restrict-management-to-localhost = cfg.proxy.restrictManagementToLocalhost;
          model-mappings = cfg.proxy.modelMappings
            ++ lib.optional (cfg.proxy.routeAllTo != null) {
            from = ".*";
            to = cfg.proxy.routeAllTo;
            regex = true;
          };
          force-model-mappings = cfg.proxy.forceModelMappings || cfg.proxy.routeAllTo != null;
        };
      };
      proxyConfig =
        proxyConfigBase
        // lib.optionalAttrs (cfg.proxy.apiKeys != [ ]) {
          api-keys = cfg.proxy.apiKeys;
        }
        // lib.optionalAttrs (cfg.proxy.remoteManagementSecretKey != null) {
          remote-management = {
            secret-key = cfg.proxy.remoteManagementSecretKey;
            allow-remote = cfg.proxy.remoteManagementAllowRemote;
          };
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
      proxyMgmtBase = "http://${cfg.proxy.host}:${toString cfg.proxy.port}/v0/management";
      proxyMgmtKeyPath =
        if cfg.sops.enable then
          config.sops.secrets."amp-client-api-key".path
        else
          null;
      proxyMgmtKeyCommand =
        if proxyMgmtKeyPath != null then
          "cat ${proxyMgmtKeyPath}"
        else if cfg.proxy.remoteManagementSecretKey != null then
          "printf %s ${lib.escapeShellArg cfg.proxy.remoteManagementSecretKey}"
        else
          null;
      curlBin = lib.getExe pkgs.curl;
      fzfBin = lib.getExe pkgs.fzf;
      jqBin = lib.getExe pkgs.jq;
      rgBin = lib.getExe pkgs.ripgrep;
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
      proxyReloadCommand =
        if pkgs.stdenv.isDarwin then
          "launchctl kickstart -k gui/$UID/org.nix-community.home.cli-proxy-api"
        else
          "systemctl --user restart cli-proxy-api.service";
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
          modelChoices = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Model choices for the proxy route TUI.";
          };
          requestLog = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable CLIProxyAPI request logging (for model inspection).";
          };
          remoteManagementSecretKey = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "CLIProxyAPI remote management key (stored in Nix store if set).";
          };
          remoteManagementAllowRemote = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Allow remote (non-localhost) access to CLIProxyAPI management API.";
          };
          routeAllTo = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Route all Amp model requests to a single local model via a regex mapping.";
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
          ++ lib.optional cfg.proxy.enable pkgs.fzf
          ++ lib.optional cfg.proxy.enable pkgs.jq
          ++ lib.optional cfg.proxy.enable pkgs.ripgrep
          ++ lib.optional (cfg.proxy.package == null && lib.hasAttr "cli-proxy-api" pkgs) pkgs.cli-proxy-api;

        programs.fish.functions = lib.mkIf cfg.proxy.enable (
          {
            proxy = {
              description = "Login to Gemini via CLIProxyAPI.";
              body = ''
                ${proxyLoginCommand} $argv
              '';
            };
            proxy-codex = {
              description = "Login to Codex via CLIProxyAPI.";
              body = ''
                ${proxyCodexLoginCommand} $argv
              '';
            };
            proxy-claude = {
              description = "Login to Claude via CLIProxyAPI.";
              body = ''
                ${proxyClaudeLoginCommand} $argv
              '';
            };
          }
          // lib.optionalAttrs (proxyMgmtKeyCommand != null) {
            proxy-route = {
              description = "Route all Amp requests to a local model via CLIProxyAPI.";
              body = ''
                set -l command $argv[1]
                if test -z "$command"
                  echo "usage: proxy-route <model> | proxy-route status | proxy-route off"
                  return 1
                end
                set -l key (${proxyMgmtKeyCommand})
                switch "$command"
                  case status
                    ${curlBin} -sS -X GET "${proxyMgmtBase}/ampcode/model-mappings" \
                      -H "Authorization: Bearer $key"
                  case off clear disable
                    ${curlBin} -sS -X DELETE "${proxyMgmtBase}/ampcode/model-mappings" \
                      -H "Authorization: Bearer $key"
                    ${curlBin} -sS -X PUT "${proxyMgmtBase}/ampcode/force-model-mappings" \
                      -H "Authorization: Bearer $key" \
                      -H "Content-Type: application/json" \
                      -d "{\"value\":false}"
                    ${proxyReloadCommand}
                  case '*'
                    set -l model "$command"
                    ${curlBin} -sS -X PUT "${proxyMgmtBase}/ampcode/model-mappings" \
                      -H "Authorization: Bearer $key" \
                      -H "Content-Type: application/json" \
                      -d "{\"value\":[{\"from\":\".*\",\"to\":\"$model\",\"regex\":true}]}"
                    ${curlBin} -sS -X PUT "${proxyMgmtBase}/ampcode/force-model-mappings" \
                      -H "Authorization: Bearer $key" \
                      -H "Content-Type: application/json" \
                      -d "{\"value\":true}"
                    ${proxyReloadCommand}
                end
              '';
            };
            proxy-route-tui = {
              description = "Pick a model to route all Amp requests via a TUI (use --all for full list).";
              body = ''
                set -l cache_dir ${config.xdg.configHome}/cli-proxy-api
                set -l amp_cache "$cache_dir/amp-models.json"
                set -l cache "$cache_dir/models.json"
                set -l selection ""
                set -l use_amp_cache 1
                if test "$argv[1]" = "--all"
                  set use_amp_cache 0
                end
                if test $use_amp_cache -eq 1 -a -s "$amp_cache"
                  set -l amp_count (${jqBin} -r 'length' "$amp_cache")
                  if test "$amp_count" -gt 0
                    set -l selection_line (${jqBin} -r 'sort_by(.display_name // .id)[] | "\(.display_name // .id)\t\(.id)\t\(.auth_file // "")"' "$amp_cache" | ${fzfBin} --prompt="Route model> " --delimiter="\t" --with-nth=1,2)
                    if test -n "$selection_line"
                      set -l parts (string split "\t" -- "$selection_line")
                      set selection $parts[2]
                    end
                  else
                    set use_amp_cache 0
                  end
                end
                if test -z "$selection" -a $use_amp_cache -eq 0 -a -s "$cache"
                  set -l selection_line (${jqBin} -r 'sort_by(.display_name // .id)[] | "\(.display_name // .id)\t\(.id)\t\(.auth_file // "")"' "$cache" | ${fzfBin} --prompt="Route model> " --delimiter="\t" --with-nth=1,2)
                  if test -n "$selection_line"
                    set -l parts (string split "\t" -- "$selection_line")
                    set selection $parts[2]
                  end
                else
                  set -l choices \
                    ${lib.concatStringsSep " " (map lib.escapeShellArg cfg.proxy.modelChoices)}
                  if test (count $choices) -eq 0
                    echo "no models configured in modules.terminal.amp.proxy.modelChoices"
                    return 1
                  end
                  set selection (printf "%s\n" $choices | ${fzfBin} --prompt="Route model> ")
                end
                if test -z "$selection"
                  return 1
                end
                proxy-route "$selection"
              '';
            };
            proxy-models-refresh = {
              description = "Refresh cached models from CLIProxyAPI and Amp.";
              body = ''
                set -l key (${proxyMgmtKeyCommand})
                set -l cache_dir ${config.xdg.configHome}/cli-proxy-api
                set -l cache "$cache_dir/models.json"
                set -l amp_cache "$cache_dir/amp-models.json"
                mkdir -p "$cache_dir"
                set -l auth_files (${curlBin} -sS "${proxyMgmtBase}/auth-files" \
                  -H "Authorization: Bearer $key" | ${jqBin} -r '.files[].name')
                if test (count $auth_files) -eq 0
                  echo "no auth files found"
                  return 1
                end
                set -l tmp (mktemp)
                for name in $auth_files
                  set -l encoded (string escape --style=url "$name")
                  ${curlBin} -sS "${proxyMgmtBase}/auth-files/models?name=$encoded" \
                    -H "Authorization: Bearer $key" \
                    | ${jqBin} -c --arg name "$name" '.models[] | . + {auth_file: $name}' >> $tmp
                end
                if test -s "$tmp"
                  ${jqBin} -s 'unique_by(.id)' "$tmp" > "$cache"
                else
                  rm -f "$tmp"
                  echo "no models returned"
                  return 1
                end
                rm -f "$tmp"
                set -l amp_models (${curlBin} -sS https://ampcode.com/models | ${rgBin} -o 'currentModel:\"[^\"]+\"' | string replace -r 'currentModel:\"(.*)\"' '$1' | sort -u)
                if test (count $amp_models) -gt 0
                  set -l amp_json (printf "%s\n" $amp_models | ${jqBin} -R -s 'split("\n") | map(select(length>0))' | string collect)
                  ${jqBin} -n --argjson amp "$amp_json" --slurpfile cache "$cache" '$cache[0] | map(select(.display_name as $name | ($amp | index($name)))) | unique_by(.id)' > "$amp_cache"
                end
                echo "wrote $cache"
                if test -s "$amp_cache"
                  echo "wrote $amp_cache"
                end
              '';
            };
            proxy-route-off = {
              description = "Clear Amp model mappings.";
              body = ''
                set -l key (${proxyMgmtKeyCommand})
                ${curlBin} -sS -X DELETE "${proxyMgmtBase}/ampcode/model-mappings" \
                  -H "Authorization: Bearer $key"
                ${curlBin} -sS -X PUT "${proxyMgmtBase}/ampcode/force-model-mappings" \
                  -H "Authorization: Bearer $key" \
                  -H "Content-Type: application/json" \
                  -d "{\"value\":false}"
                ${proxyReloadCommand}
              '';
            };
            proxy-reload = {
              description = "Restart CLIProxyAPI to apply config changes.";
              body = ''
                ${proxyReloadCommand}
              '';
            };
            proxy-route-status = {
              description = "Show current Amp model mappings.";
              body = ''
                set -l key (${proxyMgmtKeyCommand})
                ${curlBin} -sS -X GET "${proxyMgmtBase}/ampcode/model-mappings" \
                  -H "Authorization: Bearer $key"
              '';
            };
            proxy-log-on = {
              description = "Enable CLIProxyAPI request logging.";
              body = ''
                set -l key (${proxyMgmtKeyCommand})
                ${curlBin} -sS -X PUT "${proxyMgmtBase}/request-log" \
                  -H "Authorization: Bearer $key" \
                  -H "Content-Type: application/json" \
                  -d "{\"value\":true}"
              '';
            };
            proxy-log-off = {
              description = "Disable CLIProxyAPI request logging.";
              body = ''
                set -l key (${proxyMgmtKeyCommand})
                ${curlBin} -sS -X PUT "${proxyMgmtBase}/request-log" \
                  -H "Authorization: Bearer $key" \
                  -H "Content-Type: application/json" \
                  -d "{\"value\":false}"
              '';
            };
            proxy-log-status = {
              description = "Show whether request logging is enabled.";
              body = ''
                set -l key (${proxyMgmtKeyCommand})
                ${curlBin} -sS -X GET "${proxyMgmtBase}/request-log" \
                  -H "Authorization: Bearer $key"
              '';
            };
            proxy-last-model = {
              description = "Show the model from the latest request log.";
              body = ''
                set -l logdir ${config.xdg.configHome}/cli-proxy-api/logs
                if test ! -d "$logdir"
                  echo "no request logs found"
                  return 1
                end
                set -l candidates (ls -t $logdir/api-provider-*.log 2>/dev/null)
                if test (count $candidates) -eq 0
                  set candidates (ls -t $logdir/*.log 2>/dev/null | string match -v -r '/error-')
                end
                set -l log ""
                for entry in $candidates
                  if test -f "$entry"
                    set log "$entry"
                    break
                  end
                end
                if test -z "$log"
                  echo "no request logs found"
                  return 1
                end
                set -l match (${rgBin} -o -m 1 '"model"\\s*:\\s*"[^"]+"' "$log")
                if test -z "$match"
                  echo "model not found in $log"
                  return 1
                end
                string replace -r '.*"model"\\s*:\\s*"([^"]+)".*' '$1' -- $match
              '';
            };
          }
        );

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

        aliases = lib.mkIf cfg.proxy.enable {
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
                      remote-management = {
                        secret-key = config.sops.placeholder."amp-client-api-key";
                        allow-remote = cfg.proxy.remoteManagementAllowRemote;
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
