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

      notifyScript = ''
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

        title = osa_escape("Claude Code")
        body = osa_escape(str(data.get("message") or "Claude Code notification"))

        subprocess.run(
            ["/usr/bin/osascript", "-e", f'display notification "{body}" with title "{title}"'],
            check=False,
        )
      '';

      # Rendered from the fully-merged settings (this module + zellij.nix + any
      # other contributor), matching what home-manager would otherwise symlink.
      settingsFile = (pkgs.formats.json { }).generate "claude-code-settings.json" (
        config.programs.claude-code.settings
        // {
          "$schema" = "https://json.schemastore.org/claude-code-settings.json";
        }
      );

      # Claude Code, /config, and plugin installers (claude-mem) rewrite
      # settings.json in place, so it can't be a read-only store symlink. Seed a
      # writable file, keeping any local edits (e.g. enabledPlugins).
      seedSettings = pkgs.writeShellApplication {
        name = "seed-claude-settings";
        runtimeInputs = [ pkgs.jq pkgs.coreutils ];
        text = ''
          target=$1
          baseline=$2
          mkdir -p "$(dirname "$target")"
          if [ -f "$target" ] && [ ! -L "$target" ]; then
            merged=$(jq -s '.[0] * .[1]' "$target" "$baseline")
            printf '%s\n' "$merged" >"$target"
          else
            rm -f "$target"
            install -m 644 "$baseline" "$target"
          fi
        '';
      };
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
          claude-agent-acp # ACP provider for agentic.nvim

          # Assistant
          # picoclaw # Hash mismatch

          # Dev
          tuicr # Review AI-generated diffs like a GitHub pull request, right from your terminal
          spec-kit # Bootstrap strict technical specs for Claude Max to follow

          # Multiagent / Workspace
          workmux # Easily make new tmux window + git worktree
          agent-deck # AI Agent command center

          # Util
          entire # links AI sessions to code changes
          rtk # Reduce input tokens
          openskills # port SKILLS.md to other providers
          happy-coder # easy remote sessions
          ccusage # Usage for claude code
          gitnexus # Repo as KG for agents

          # Appearance
          ccstatusline # statusline for claude

          # Security
          claudebox # Containerize claude code easily

          # LLM proxy for claude code
          cli-proxy-api
        ];
        programs = {
          claude-code = {
            enable = true;
            settings = {
              model = "claude-sonnet-4-6";
              hooks.Notification = lib.optionals pkgs.stdenv.isDarwin [
                { hooks = [ { type = "command"; command = "${pkgs.python3}/bin/python3 -c ${lib.escapeShellArg notifyScript}"; } ]; }
              ];
            };
          };
          opencode = {
            enable = true;
            enableMcpIntegration = true;
            settings.plugin = [ "opencode-gemini-auth@latest" ];
          };
        };

        home.file.".claude/settings.json".enable = lib.mkForce false;
        home.activation.claudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ]
          "run ${lib.getExe seedSettings} ${config.home.homeDirectory}/.claude/settings.json ${settingsFile}";
      };
    };
}
