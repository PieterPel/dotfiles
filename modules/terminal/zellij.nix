{
  flake.modules.homeManager.zellij =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.modules.terminal.zellij;

      zellijBin = lib.getExe pkgs.zellij;

      claudeZellijHook = pkgs.writeShellApplication {
        name = "claude-zellij-hook";
        runtimeInputs = [
          pkgs.jq
          pkgs.zellij
        ];
        text = ''
          STATE_DIR="/tmp/claude-zellij-status"
          ZELLIJ_SESSION="''${ZELLIJ_SESSION_NAME:-}"
          ZELLIJ_PANE="''${ZELLIJ_PANE_ID:-0}"

          [ -z "$ZELLIJ_SESSION" ] && exit 0

          STATE_FILE="''${STATE_DIR}/''${ZELLIJ_SESSION}.json"
          mkdir -p "$STATE_DIR"

          INPUT=$(cat)

          HOOK_EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // ""' 2>/dev/null || echo "")
          TOOL_NAME=$(echo "$INPUT"  | jq -r '.tool_name // ""'       2>/dev/null || echo "")
          SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")
          CWD=$(echo "$INPUT"        | jq -r '.cwd // ""'              2>/dev/null || echo "")

          [ -z "$HOOK_EVENT" ] && exit 0

          PROJECT_NAME=$(basename "$CWD" 2>/dev/null || echo "?")
          if [ ''${#PROJECT_NAME} -gt 12 ]; then
            PROJECT_NAME="''${PROJECT_NAME:0:6}..."
          fi

          C_GREEN="#2ecc40"
          C_YELLOW="#ffdc00"
          C_BLUE="#0074d9"
          C_AQUA="#4166F5"
          C_RED="#ff4136"
          C_ORANGE="#ff851b"
          C_PURPLE="#b10dc9"
          C_GRAY="#666666"

          DONE=false
          case "$HOOK_EVENT" in
            PreToolUse)
              case "$TOOL_NAME" in
                WebSearch)       ACTIVITY="search"; COLOR="$C_BLUE";   SYMBOL="◍" ;;
                WebFetch)        ACTIVITY="fetch";  COLOR="$C_BLUE";   SYMBOL="↓" ;;
                Task)            ACTIVITY="agent";  COLOR="$C_PURPLE"; SYMBOL="▶" ;;
                Bash)            ACTIVITY="bash";   COLOR="$C_ORANGE"; SYMBOL="⚡" ;;
                Read)            ACTIVITY="read";   COLOR="$C_BLUE";   SYMBOL="◔" ;;
                Write)           ACTIVITY="write";  COLOR="$C_AQUA";   SYMBOL="✎" ;;
                Edit)            ACTIVITY="edit";   COLOR="$C_AQUA";   SYMBOL="✎" ;;
                Glob|Grep)       ACTIVITY="find";   COLOR="$C_BLUE";   SYMBOL="◎" ;;
                Skill)           ACTIVITY="skill";  COLOR="$C_PURPLE"; SYMBOL="★" ;;
                TodoWrite)       ACTIVITY="plan";   COLOR="$C_YELLOW"; SYMBOL="◫" ;;
                AskUserQuestion) ACTIVITY="ask?";   COLOR="$C_RED";    SYMBOL="?" ;;
                mcp__*)          ACTIVITY="mcp";    COLOR="$C_PURPLE"; SYMBOL="◈" ;;
                *)               ACTIVITY="work";   COLOR="$C_YELLOW"; SYMBOL="●" ;;
              esac ;;
            PostToolUse)
              ACTIVITY="think"; COLOR="$C_GRAY"; SYMBOL="◐" ;;
            Notification)
              if [ -f "$STATE_FILE" ]; then
                EXISTING_DONE=$(jq -r --arg pane "$ZELLIJ_PANE" '.[$pane].done // false' "$STATE_FILE" 2>/dev/null || echo "false")
                if [ "$EXISTING_DONE" = "true" ]; then
                  PROJECT_NAME_NOTIFY=$(basename "$CWD" 2>/dev/null || echo "?")
                  ${zellijBin} -s "$ZELLIJ_SESSION" pipe "zjstatus::notify::''${PROJECT_NAME_NOTIFY} ! notification" 2>/dev/null || true
                  exit 0
                fi
              fi
              ACTIVITY="!"; COLOR="$C_RED"; SYMBOL="!" ;;
            UserPromptSubmit)
              ACTIVITY="start"; COLOR="$C_YELLOW"; SYMBOL="●" ;;
            PermissionRequest)
              ACTIVITY="perm?"; COLOR="$C_RED"; SYMBOL="⚠" ;;
            Stop)
              ACTIVITY="done"; COLOR="$C_GREEN"; SYMBOL="✓"; DONE=true ;;
            SubagentStop)
              ACTIVITY="agent✓"; COLOR="$C_GREEN"; SYMBOL="▷" ;;
            SessionStart)
              ACTIVITY="init"; COLOR="$C_BLUE"; SYMBOL="◆" ;;
            SessionEnd)
              if [ -f "$STATE_FILE" ]; then
                TMP_FILE=$(mktemp)
                jq --arg pane "$ZELLIJ_PANE" 'del(.[$pane])' "$STATE_FILE" > "$TMP_FILE" 2>/dev/null && mv "$TMP_FILE" "$STATE_FILE"
                rm -f "$TMP_FILE"
              fi
              ${switchCmd} end 2>/dev/null || true
              exit 0 ;;
            *)
              ACTIVITY="..."; COLOR="$C_GRAY"; SYMBOL="○" ;;
          esac

          TIME_FMT=$(date +%H:%M)
          TIMESTAMP=$(date +%s)

          [ ! -f "$STATE_FILE" ] || [ ! -s "$STATE_FILE" ] && echo "{}" > "$STATE_FILE"
          CURRENT_STATE=$(cat "$STATE_FILE" 2>/dev/null || echo "{}")
          echo "$CURRENT_STATE" | jq empty 2>/dev/null || { CURRENT_STATE="{}"; echo "{}" > "$STATE_FILE"; }

          TMP_FILE=$(mktemp)
          echo "$CURRENT_STATE" | jq \
            --arg pane      "$ZELLIJ_PANE" \
            --arg project   "$PROJECT_NAME" \
            --arg activity  "$ACTIVITY" \
            --arg color     "$COLOR" \
            --arg symbol    "$SYMBOL" \
            --arg time      "$TIME_FMT" \
            --arg ts        "$TIMESTAMP" \
            --arg session   "$SESSION_ID" \
            --argjson "done" "$DONE" \
            '.[$pane] = {
              project:  $project,
              activity: $activity,
              color:    $color,
              symbol:   $symbol,
              time:     $time,
              timestamp: ($ts | tonumber),
              session_id: $session,
              done: $done
            }' > "$TMP_FILE" 2>/dev/null
          if [ -s "$TMP_FILE" ]; then mv "$TMP_FILE" "$STATE_FILE"; else rm -f "$TMP_FILE"; fi

          case "$HOOK_EVENT" in
            Stop)
              ${zellijBin} action focus-pane-id "$ZELLIJ_PANE" 2>/dev/null || true
              ${switchCmd} stop 2>/dev/null || true ;;

            UserPromptSubmit) ${switchCmd} prompt 2>/dev/null || true ;;
          esac

          case "$HOOK_EVENT" in
            Notification|Stop|SubagentStop|AskUserQuestion|PermissionRequest)
              ${zellijBin} -s "$ZELLIJ_SESSION" pipe "zjstatus::notify::''${PROJECT_NAME} ''${SYMBOL} ''${ACTIVITY}" 2>/dev/null || true ;;
          esac
        '';
      };

      claudeZellijStatus = pkgs.writeShellApplication {
        name = "claude-zellij-status";
        runtimeInputs = [ pkgs.jq ];
        text = ''
          STATE_FILE="/tmp/claude-zellij-status/''${ZELLIJ_SESSION_NAME:-}.json"
          [ -z "''${ZELLIJ_SESSION_NAME:-}" ] && exit 0
          [ ! -f "$STATE_FILE" ] && exit 0

          SESSIONS=""
          while IFS= read -r line; do
            [ -z "$line" ] && continue
            [ -n "$SESSIONS" ] && SESSIONS="''${SESSIONS}  "
            SESSIONS="''${SESSIONS}''${line}"
          done < <(jq -r '
            to_entries | sort_by(.key)[] |
            "#[fg=\(.value.color)]\(.value.symbol) #[fg=#4166F5]\(.value.project)"
          ' "$STATE_FILE" 2>/dev/null)

          [ -n "$SESSIONS" ] && printf '%s' "$SESSIONS"
        '';
      };

      claudeZellijSwitch = pkgs.writers.writePython3Bin "claude-zellij-switch" { } ''
        import json
        import os
        import subprocess
        import sys
        import time
        from pathlib import Path

        STATE_DIR = Path("/tmp/claude-zellij-status")
        QUEUE_FILE = STATE_DIR / ".attention.json"
        SESSION = os.environ.get("ZELLIJ_SESSION_NAME", "")
        ZELLIJ = "${lib.getExe pkgs.zellij}"

        if not SESSION:
            sys.exit(0)


        def read_queue():
            try:
                return json.loads(QUEUE_FILE.read_text())
            except Exception:
                return []


        def write_queue(queue):
            QUEUE_FILE.write_text(json.dumps(queue))


        def live_sessions():
            out = subprocess.run(
                [ZELLIJ, "list-sessions"],
                capture_output=True,
                text=True,
            ).stdout
            return [
                line.split()[0]
                for line in out.splitlines()
                if line.strip() and "EXITED" not in line
            ]


        def switch(target, via=None):
            cmd = [ZELLIJ, "-s", via] if via else [ZELLIJ]
            subprocess.run(
                cmd + ["action", "switch-session", target],
                capture_output=True,
            )


        mode = sys.argv[1] if len(sys.argv) > 1 else ""

        if mode == "stop":
            queue = read_queue()
            was_empty = len(queue) == 0
            queue = [e for e in queue if e["session"] != SESSION]
            queue.append({"session": SESSION, "ts": int(time.time())})
            write_queue(queue)
            if was_empty:
                for other in live_sessions():
                    if other != SESSION:
                        switch(SESSION, via=other)

        elif mode == "prompt":
            queue = read_queue()
            waiting = [e for e in queue if e["session"] != SESSION]
            if waiting:
                target = max(waiting, key=lambda e: e["ts"])
                queue = [e for e in queue if e["session"] != target["session"]]
                write_queue(queue)
                switch(target["session"])

        elif mode == "end":
            write_queue([e for e in read_queue() if e["session"] != SESSION])
      '';

      hookCmd = lib.getExe claudeZellijHook;
      statusCmd = lib.getExe claudeZellijStatus;
      switchCmd = lib.getExe claudeZellijSwitch;

      hookEntry = {
        hooks = [
          {
            type = "command";
            command = hookCmd;
          }
        ];
      };
    in
    {
      options.modules.terminal.zellij = {
        enable = lib.mkEnableOption "Enable Zellij configuration.";
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ pkgs.zellij ];

        # Main config — theme + keybinds
        xdg.configFile."zellij/config.kdl".text = ''
          theme "catppuccin-mocha"
          default_shell "${lib.getExe pkgs.fish}"
          pane_frames false
          mouse_mode true
          scroll_buffer_size 10000
          copy_on_select true
          session_serialization true
          default_layout "default"

          keybinds {
            normal {
              bind "Ctrl a" { SwitchToMode "tmux"; }
            }

            tmux {
              bind "Ctrl a" { Write 1; SwitchToMode "Normal"; }
              bind "Esc"    { SwitchToMode "Normal"; }

              // Splits
              bind "d" { NewPane "Right"; SwitchToMode "Normal"; }
              bind "v" { NewPane "Down";  SwitchToMode "Normal"; }

              // Pane navigation (hjkl)
              bind "h" { MoveFocus "Left";  SwitchToMode "Normal"; }
              bind "j" { MoveFocus "Down";  SwitchToMode "Normal"; }
              bind "k" { MoveFocus "Up";    SwitchToMode "Normal"; }
              bind "l" { MoveFocus "Right"; SwitchToMode "Normal"; }

              // Tabs
              bind "c" { NewTab;            SwitchToMode "Normal"; }
              bind "x" { CloseFocus;        SwitchToMode "Normal"; }
              bind "p" { GoToPreviousTab;   SwitchToMode "Normal"; }
              bind "n" { GoToNextTab;       SwitchToMode "Normal"; }
              bind "w" { SwitchToMode "Tab"; }

              // Sessions
              bind "S" { LaunchOrFocusPlugin "zellij:session-manager" { floating true; move_to_focused_tab true; }; SwitchToMode "Normal"; }

              // Resize
              bind "Alt h" { Resize "Increase Left";  SwitchToMode "Normal"; }
              bind "Alt j" { Resize "Increase Down";  SwitchToMode "Normal"; }
              bind "Alt k" { Resize "Increase Up";    SwitchToMode "Normal"; }
              bind "Alt l" { Resize "Increase Right"; SwitchToMode "Normal"; }
            }

            shared_except "normal" "locked" {
              bind "Esc" { SwitchToMode "Normal"; }
            }

            locked {
              bind "Ctrl g" { SwitchToMode "Normal"; }
            }
          }
        '';

        # Default layout with zjstatus bar
        xdg.configFile."zellij/layouts/default.kdl".text = ''
          layout {
            default_tab_template {
              children
              pane size=1 borderless=true {
                plugin location="file:${pkgs.zellijPlugins.zjstatus}" {
                  format_left   "{mode}#[fg=#6A18D1,bold] {session} {tabs}"
                  format_center ""
                  format_right  "{command_git_branch} {command_claude_status} {notifications} {datetime}"
                  format_space  ""

                  border_enabled  "false"
                  hide_frame_for_single_pane "false"

                  mode_normal  "#[bg=#6A18D1,fg=#cdd6f4,bold]  "
                  mode_tmux    "#[bg=#f38ba8,fg=#1e1e2e,bold]  "
                  mode_locked  "#[bg=#585b70,fg=#cdd6f4,bold]  "
                  mode_pane    "#[bg=#89b4fa,fg=#1e1e2e,bold]  "
                  mode_tab     "#[bg=#a6e3a1,fg=#1e1e2e,bold]  "
                  mode_resize  "#[bg=#fab387,fg=#1e1e2e,bold]  "
                  mode_scroll  "#[bg=#f9e2af,fg=#1e1e2e,bold]  "
                  mode_search  "#[bg=#89dceb,fg=#1e1e2e,bold]  "

                  tab_normal         "#[fg=#585b70] {name} "
                  tab_active         "#[fg=#cdd6f4,bold] {name} "
                  tab_fullscreen     "#[fg=#f38ba8,bold] {name} [] "
                  tab_sync           "#[fg=#fab387,bold] {name} <> "

                  command_git_branch_command    "git rev-parse --abbrev-ref HEAD"
                  command_git_branch_format     "#[fg=#6A18D1] {stdout} "
                  command_git_branch_interval   "10"
                  command_git_branch_rendermode "static"

                  datetime        "#[fg=#585b70,bold] {format} "
                  datetime_format "%H:%M"
                  datetime_timezone "Europe/Amsterdam"

                  notifications_format_unread          "#[fg=#89b4fa,bg=#181825] {message} "
                  notifications_format_no_notifications ""
                  notifications_show_interval "10"

                  command_claude_status_command    "${statusCmd}"
                  command_claude_status_format     "#[fg=#585b70]│ {stdout}"
                  command_claude_status_interval   "2"
                  command_claude_status_rendermode "dynamic"
                }
              }
            }
          }
        '';

        # Claude Code hooks — write activity to zjstatus pipe
        programs.claude-code.settings.hooks = {
          PreToolUse = [ hookEntry ];
          PostToolUse = [ hookEntry ];
          UserPromptSubmit = [ hookEntry ];
          PermissionRequest = [ hookEntry ];
          Notification = [ hookEntry ];
          Stop = [ hookEntry ];
          SubagentStop = [ hookEntry ];
          SessionStart = [ hookEntry ];
          SessionEnd = [ hookEntry ];
        };
      };
    };
}
