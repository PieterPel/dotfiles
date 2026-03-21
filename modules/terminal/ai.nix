{ inputs, ... }:
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
        packages = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
          # TUI
          gemini-cli
          code # Codex fork that also supports claude and gemini
          mistral-vibe
          sidecar # Terminal-based companion to orchestrate your AI agents alongside Neovim
          beads-viewer # Graph-aware TUI for navigating your local issue tracker

          # Assistant
          picoclaw

          # Tracker (Added for the local-first workflow)
          beads-rust # Fast, local-first issue tracker right in your git repo

          # Dev
          tuicr # Review AI-generated diffs like a GitHub pull request, right from your terminal
          spec-kit # Bootstrap strict technical specs for Claude Max to follow

          # Multiagent / Workspace
          workmux # Easily make new tmux window + git worktree

          # Util
          entire # links AI sessions to code changes
          rtk # Reduce input tokens
          openskills # port SKILLS.md to other providers
          happy # easy remote sessions

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
        };
      };
    };
}
