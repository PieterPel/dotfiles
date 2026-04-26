{
  flake.modules.homeManager.tmux =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.modules.terminal.tmux;
      fish = lib.getExe pkgs.fish;

      promoteScript = pkgs.writeShellScriptBin "tmux-promote" ''
        set -euo pipefail

        current_pane=$(tmux display-message -p '#{pane_id}')
        pane_path=$(tmux display-message -p '#{pane_current_path}')
        new_pane=$(tmux new-window -P -F '#{pane_id}' -n 'promoted' -c "''${pane_path}")

        tmux join-pane -s "''${current_pane}" -t "''${new_pane}"
        tmux select-pane -t "''${current_pane}"
        tmux kill-pane -t "''${new_pane}"
      '';

      promote = lib.getExe' promoteScript "tmux-promote";

      fzf-tmux = pkgs.lib.getExe' pkgs.fzf "fzf-tmux";

      claudeTmux = pkgs.rustPlatform.buildRustPackage {
        pname = "claude-tmux";
        version = "0.3.0";
        src = pkgs.fetchFromGitHub {
          owner = "nielsgroen";
          repo = "claude-tmux";
          rev = "212a5b55cc88e35feb7fd14b4508959a60a625ca";
          hash = "sha256-fNBT3DItgTrO0vKhjAAQ6L6/K9SBpvXEnyNUOq1AP4M=";
        };
        cargoHash = "sha256-AKBNCHx6Ap6HKddwzxs/qfJhJDE7LdZ/tRKO94ugRkA=";
        nativeBuildInputs = [ pkgs.pkg-config ];
        buildInputs = [ pkgs.openssl pkgs.libgit2 pkgs.libiconv ];
        meta.mainProgram = "claude-tmux";
      };

      paletteScript = pkgs.writeShellScriptBin "tmux-command-palette" ''
        set -euo pipefail

        if ! command -v fzf >/dev/null 2>&1; then
          echo "fzf not found in PATH" >&2
          exit 1
        fi

        list_commands() {
          if command -v compgen >/dev/null 2>&1; then
            compgen -c
            return 0
          fi

          # Fallback for shells without compgen: scan PATH for executables.
          local path_env
          path_env="''${PATH:-}"
          local IFS=:
          local dir
          for dir in $path_env; do
            [ -d "$dir" ] || continue
            local file
            for file in "$dir"/*; do
              [ -f "$file" ] && [ -x "$file" ] && basename "$file"
            done
          done
        }

        cmd=$(list_commands | sort -u | fzf --prompt="Run> " --height=100%)
        if [ -n "$cmd" ]; then
          tmux new-window "$cmd"
        fi
      '';

      palette = lib.getExe' paletteScript "tmux-command-palette";

      windowPickerScript = pkgs.writeShellScriptBin "tmux-window-picker" ''
        set -euo pipefail
        export PATH="${lib.makeBinPath [ pkgs.fzf ]}:$PATH"

        tmux list-windows -a -F '#{session_name}:#{window_id} #{window_name} #{pane_current_command} [#{pane_current_path}]' \
          | fzf --prompt 'Windows> ' \
                --preview 'tmux capture-pane -ep -t {1}' \
                --preview-window 'right:60%,border-left' \
                --bind 'enter:execute(tmux switch-client -t {1})+accept'
      '';

      windowPicker = lib.getExe' windowPickerScript "tmux-window-picker";

      gitStatusScript = pkgs.writeShellScriptBin "tmux-git-status" ''
        set -euo pipefail
        cd "$1" 2>/dev/null || exit 0

        if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
          exit 0
        fi

        branch=$(git rev-parse --abbrev-ref HEAD)
        stats=$(git diff HEAD --shortstat 2>/dev/null | sed 's/^ //')

        if [ -n "$stats" ]; then
          clean_stats=$(echo "$stats" | sed -E 's/([^0-9]+)([0-9]+) file.*/\2f/; s/([^0-9]+)([0-9]+) ins.*/ +\2/; s/([^0-9]+)([0-9]+) del.*/ -\2/')
          echo "#[fg=#6A18D1] $branch #[fg=cyan][$clean_stats]"
        else
          echo "#[fg=#6A18D1] $branch #[fg=green][clean]"
        fi
      '';

      gitStatus = lib.getExe' gitStatusScript "tmux-git-status";

      sessionStatusScript = pkgs.writeShellScriptBin "tmux-session-status" ''
        set -euo pipefail

        # Build pid->ppid table in one ps call instead of one subprocess per lookup
        declare -A ppid_map
        while read -r pid ppid; do
          ppid_map[$pid]=$ppid
        done < <(ps -eo pid=,ppid= 2>/dev/null)

        find_claude_status() {
          local pane_pid="$1"
          for sf in "$HOME/.claude/sessions/"*.json; do
            [ -f "$sf" ] || continue
            local claude_pid cur depth
            claude_pid=$(basename "$sf" .json)
            cur="$claude_pid" depth=0
            while [ -n "$cur" ] && [ "$cur" != "0" ] && [ "$depth" -lt 8 ]; do
              if [ "$cur" = "$pane_pid" ]; then
                ${pkgs.jq}/bin/jq -r '.status // ""' "$sf" 2>/dev/null
                return
              fi
              cur="''${ppid_map[$cur]:-}"
              depth=$((depth + 1))
            done
          done
          echo ""
        }

        claude_badge() {
          local session="$1" seg_fg="$2"
          local busy=0 idle=0 waiting=0
          while IFS= read -r pane_pid; do
            case "$(find_claude_status "$pane_pid")" in
              busy)    busy=$((busy + 1)) ;;
              idle)    idle=$((idle + 1)) ;;
              waiting) waiting=$((waiting + 1)) ;;
            esac
          done < <(tmux list-panes -s -t "$session" -F '#{pane_pid}' 2>/dev/null)
          if [ "$busy" -gt 0 ]; then
            printf ' #[fg=#a6e3a1]●%s#[fg=%s]' "$busy" "$seg_fg"
          elif [ "$waiting" -gt 0 ]; then
            printf ' #[fg=#f38ba8]●%s#[fg=%s]' "$waiting" "$seg_fg"
          elif [ "$idle" -gt 0 ]; then
            printf ' #[fg=#585b70]○%s#[fg=%s]' "$idle" "$seg_fg"
          fi
        }

        sessions=($(tmux list-sessions -F '#S' 2>/dev/null))
        current=$(tmux display-message -p '#S')
        count=''${#sessions[@]}
        output=""

        for i in "''${!sessions[@]}"; do
          s="''${sessions[$i]}"
          num=$((i + 1))

          if [ "$s" = "$current" ]; then
            seg_bg="#6A18D1"
            seg_fg="#ffffff"
            seg_bold="bold"
          else
            seg_bg="#313244"
            seg_fg="#bac2de"
            seg_bold="nobold"
          fi

          badge=$(claude_badge "$s" "$seg_fg")
          output+="#[fg=$seg_fg,bg=$seg_bg,$seg_bold] $num $s$badge "

          next_i=$((i + 1))
          if [ "$next_i" -lt "$count" ]; then
            next_s="''${sessions[$next_i]}"
            if [ "$next_s" = "$current" ]; then
              next_bg="#6A18D1"
            else
              next_bg="#313244"
            fi
          else
            next_bg="#1e1e2e"
          fi
          output+="#[fg=$seg_bg,bg=$next_bg,nobold]"
        done

        echo "$output"
      '';

      sessionStatus = lib.getExe' sessionStatusScript "tmux-session-status";

      # Receives a window_id (@N), checks all panes in that window so the status
      # is visible regardless of which pane is currently focused.
      claudeStatusScript = pkgs.writeShellScriptBin "tmux-claude-status" ''
        set -euo pipefail

        declare -A ppid_map
        while read -r pid ppid; do
          ppid_map[$pid]=$ppid
        done < <(ps -eo pid=,ppid= 2>/dev/null)

        find_claude_status() {
          local pane_pid="$1"
          for sf in "$HOME/.claude/sessions/"*.json; do
            [ -f "$sf" ] || continue
            local claude_pid cur depth
            claude_pid=$(basename "$sf" .json)
            cur="$claude_pid" depth=0
            while [ -n "$cur" ] && [ "$cur" != "0" ] && [ "$depth" -lt 8 ]; do
              if [ "$cur" = "$pane_pid" ]; then
                ${pkgs.jq}/bin/jq -r '.status // ""' "$sf" 2>/dev/null
                return
              fi
              cur="''${ppid_map[$cur]:-}"
              depth=$((depth + 1))
            done
          done
          echo ""
        }

        window_id="''${1:-}"
        busy=0 waiting=0 idle=0

        while IFS= read -r pane_pid; do
          case "$(find_claude_status "$pane_pid")" in
            busy)    busy=$((busy + 1)) ;;
            waiting) waiting=$((waiting + 1)) ;;
            idle)    idle=$((idle + 1)) ;;
          esac
        done < <(tmux list-panes -t "$window_id" -F '#{pane_pid}' 2>/dev/null)

        if [ "$busy" -gt 0 ]; then
          printf '#[fg=#a6e3a1]● '
        elif [ "$waiting" -gt 0 ]; then
          printf '#[fg=#f38ba8]● '
        elif [ "$idle" -gt 0 ]; then
          printf '#[fg=#585b70]○ '
        fi
      '';

      claudeStatus = lib.getExe' claudeStatusScript "tmux-claude-status";

      # On session switch, bust the #() cache by appending the session name as a
      # shell comment — tmux sees a new command string and runs it immediately.
      sessionSwitchHookScript = pkgs.writeShellScriptBin "tmux-session-switch-hook" ''
        session="''${1:-}"
        tmux set-option -g 'status-format[1]' "#[bg=#1e1e2e]#(${sessionStatus} # $session)"
        tmux refresh-client -S
      '';

      sessionSwitchHook = lib.getExe' sessionSwitchHookScript "tmux-session-switch-hook";
    in
    {
      options.modules.terminal.tmux = {
        enable = lib.mkEnableOption "Enable Tmux configuration.";
      };

      config = lib.mkIf cfg.enable {
        programs.tmux = {
          enable = true;
          terminal = "tmux-256color";
          baseIndex = 1;
          keyMode = "vi";
          shell = "${pkgs.fish}/bin/fish";
          historyLimit = 10000;
          plugins = with pkgs.tmuxPlugins; [
            better-mouse-mode
            prefix-highlight
            continuum
            resurrect
            yank
            {
              plugin = catppuccin;
              extraConfig = ''
                set -g @catppuccin_flavor 'mocha'
                set -g @catppuccin_status_background '#1e1e2e'
                set -g @catppuccin_window_status_style 'slanted'
                set -g @catppuccin_window_current_text '#(${claudeStatus} #{window_id})#W'
                set -g @catppuccin_window_text '#(${claudeStatus} #{window_id})#W'
              '';
            }
            {
              plugin = pkgs.tmuxPlugins.mkTmuxPlugin {
                pluginName = "smart-splits";
                version = "unstable-2025-12-26";
                src = pkgs.fetchFromGitHub {
                  owner = "mrjones2014";
                  repo = "smart-splits.nvim";
                  rev = "1ea2e55bcc0dd2bdec5c5fef0082219f76c532fc";
                  sha256 = "sha256-D5Yf9GTFpLMDS8zUHHkNM2BUCnwxMBnyyr2lQFAxouA=";
                };
                rtpFilePath = "smart-splits.tmux";
              };
              extraConfig = ''
                set -g @smart-splits_move_left_key  'C-h'
                set -g @smart-splits_move_down_key  'C-j'
                set -g @smart-splits_move_up_key    'C-k'
                set -g @smart-splits_move_right_key 'C-l'
                set -g @smart-splits_resize_left_key  'M-h'
                set -g @smart-splits_resize_down_key  'M-j'
                set -g @smart-splits_resize_up_key    'M-k'
                set -g @smart-splits_resize_right_key 'M-l'
              '';
            }
          ];
          extraConfig = ''
              # General
              set -gu default-command
              set -g default-shell "$SHELL"
              set-option -g allow-rename off # Don't rename self-named windows
              set-option -g wrap-search on # Go from window N to window 1
              set -g allow-passthrough on
              set -s extended-keys on
              set -as terminal-features 'xterm*:extkeys'
              set -g status-interval 1
              set -g focus-events on

              # Two-row status bar:
              #   format[0] (bottom): catppuccin window tabs — clickable (default tmux row)
              #   format[1] (top):    session list with numbers and Claude badges
              set -g status 2
              set -g status-left ""
              set -g status-right "#(${gitStatus} \"#{pane_current_path}\")"
              set -g status-right-length 150

              # Override catppuccin's mauve accent to Rebels purple
              set -g @thm_mauve '#6A18D1'

              # format[0] (bottom): window tabs; tmux 3.6 default is empty so set explicitly
              set -g status-format[0] "#[align=left range=left]#{E:status-left}#[norange default]#[list=on align=#{status-justify}]#[list=left-marker]<#[list=right-marker]>#[list=on]#{W:#[range=window|#{window_id} #{E:window-status-style}]#[push-default]#{T:window-status-format}#[pop-default]#[norange default]#{?window_end_flag,,#{window-status-separator}},#[range=window|#{window_id} list=focus #{?#{!=:#{E:window-status-current-style},default},#{E:window-status-current-style},#{E:window-status-style}}]#[push-default]#{T:window-status-current-format}#[pop-default]#[norange default]#{?window_end_flag,,#{window-status-separator}}}#[nolist align=right range=right]#{E:status-right}#[norange default]"

              # format[1] (top): session list, numbered, with Claude status badges
              set -g status-format[1] "#[bg=#1e1e2e]#(${sessionStatus})"

              # Bust the #() cache on session switch by appending session name as a comment
              set-hook -g client-session-changed 'run-shell "${sessionSwitchHook} #{session_name}"'

              # Jump to session N with Prefix+Shift+N (1-9)
              # ##S: tmux run-shell expands ## to # so shell gets #S as literal for list-sessions -F
              bind '!' run-shell 'tmux switch-client -t "$(tmux list-sessions -F "##S" | sed -n "1p")"'
              bind '@' run-shell 'tmux switch-client -t "$(tmux list-sessions -F "##S" | sed -n "2p")"'
              bind '#' run-shell 'tmux switch-client -t "$(tmux list-sessions -F "##S" | sed -n "3p")"'
              bind '$' run-shell 'tmux switch-client -t "$(tmux list-sessions -F "##S" | sed -n "4p")"'
              bind '%' run-shell 'tmux switch-client -t "$(tmux list-sessions -F "##S" | sed -n "5p")"'
              bind '^' run-shell 'tmux switch-client -t "$(tmux list-sessions -F "##S" | sed -n "6p")"'
              bind '&' run-shell 'tmux switch-client -t "$(tmux list-sessions -F "##S" | sed -n "7p")"'
              bind '*' run-shell 'tmux switch-client -t "$(tmux list-sessions -F "##S" | sed -n "8p")"'
              bind '(' run-shell 'tmux switch-client -t "$(tmux list-sessions -F "##S" | sed -n "9p")"'

            # Allow tmux to handle floating windows correctly
            set -g detach-on-destroy off  # Don't exit tmux when closing a session
            set -g escape-time 0          # Faster response for keybindings

            ## Keybinds
            # Source conf file
            bind R source-file ~/.config/tmux/tmux.conf

            # Command palette (all commands via fzf)
            bind r display-popup -E -w 80% -h 80% "${palette}"

            # Fuzzy window picker (fzf + live preview)
            bind w display-popup -E -w 80% -h 80% "${windowPicker}"
            # Default tmux window chooser moved to W
            bind W choose-tree -Zw

            # Claude Code picker (claude-tmux TUI)
            bind a display-popup -E -w 80% -h 50% "${lib.getExe claudeTmux}"

            # Navigation between panes
            bind h select-pane -L
            bind l select-pane -R
            bind k select-pane -U
            bind j select-pane -D

            # Navigation between windows
            bind p previous-window
            bind n next-window

            # Cycle between sessions
            bind P switch-client -p
            bind N switch-client -n

            # Open new windows in current directory
            bind c new-window -c "#{pane_current_path}"

            # Split panes using | and -
            bind d split-window -h -c "#{pane_current_path}"
            bind v split-window -v -c "#{pane_current_path}"
            unbind '"'
                  unbind %

                  # Set shell to fish
                  set-option -g default-shell ${fish}

                  ## These have home-manager settings, but no NixOS settings for some reason
                  # Disable confirmation prompts (e.g., for killing panes)
                  bind-key x kill-pane
                  bind-key & kill-window

                  # Enable mouse support
                  set -g mouse on



                  # Change prefix key to Ctrl-a
                  unbind C-b
                  set -g prefix C-a
                  bind C-a send-prefix

                  # Put pane into Own window
                  bind o run-shell "${promote}"
                  bind O run-shell "${promote}"    

                  # Continuum + Resurrect
                  set -g @continuum-restore 'on'  # Auto-restore on boot
                  set -g @resurrect-strategy-nvim 'session'  # Restore nvim sessions
                  set -g @resurrect-capture-pane-contents 'on'
          '';
        };
      };
    };
}






