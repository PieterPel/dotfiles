{
  flake.modules.homeManager.ai =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.modules.terminal.ai;
    in
    {
      options.modules.terminal.ai = {
        enable = lib.mkEnableOption "Enable AI terminal configuration.";
      };

      config = lib.mkIf cfg.enable {
        packages = lib.optionals (!config.programs.amp.enable) [
          pkgs.amp-cli
        ];
        programs = {
          claude-code = {
            enable = true;
            settings = {
              hooks = {
                Notification = lib.optionals pkgs.stdenv.isDarwin [
                  {
                    hooks = [
                      {
                        type = "command";
                        command = "${pkgs.python3}/bin/python3 -c ${lib.escapeShellArg ''
                          import json
                          import subprocess
                          import sys

                          def osa_escape(value: str) -> str:
                              return (
                                  value.replace("\\", "\\\\")
                                  .replace("\"", "\\\"")
                                  .replace("\n", "\\n")
                              )

                          try:
                              data = json.load(sys.stdin)
                          except Exception:
                              data = {}

                          title = "Claude Code"
                          body = data.get("message") or "Claude Code notification"

                          title = osa_escape(str(title))
                          body = osa_escape(str(body))

                          subprocess.run(
                              [
                                  "/usr/bin/osascript",
                                  "-e",
                                  f'display notification "{body}" with title "{title}"',
                              ],
                              check=False,
                          )
                        ''}";
                      }
                    ];
                  }
                ];
              };
            };
          };
          opencode = {
            enable = true;
            enableMcpIntegration = true;
            settings = {
              plugin = [
                "opencode-gemini-auth@latest"
              ];
            };
          };
          codex = {
            enable = true;
            settings = {
              tui = {
                notifications = true;
                notification_method = "osc9";
                animations = false;
              };
              #   notify = lib.optionals pkgs.stdenv.isDarwin [
              #     "${pkgs.python3}/bin/python3"
              #     "-c"
              #     ''
              #       import json
              #       import subprocess
              #       import sys
              #
              #       def osa_escape(value: str) -> str:
              #           return (
              #               value.replace("\\", "\\\\")
              #               .replace('"', '\\"')
              #               .replace("\n", "\\n")
              #           )
              #
              #       try:
              #           data = json.load(sys.stdin)
              #       except Exception:
              #           data = {}
              #
              #       title = data.get("title") or data.get("event") or "Codex"
              #       body = data.get("message") or data.get("summary") or "Codex notification"
              #
              #       title = osa_escape(str(title))
              #       body = osa_escape(str(body))
              #
              #       subprocess.run(
              #           [
              #               "/usr/bin/osascript",
              #               "-e",
              #               f'display notification "{body}" with title "{title}"',
              #           ],
              #           check=False,
              #       )
              #     ''
              #   ];
            };
          };
          gemini-cli = {
            enable = lib.mkForce false;
            settings = {
              selectedAuthType = "oauth-personal";
            };
          };
        };
      };
    };
}
