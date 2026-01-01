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

      scratchScript = pkgs.writeShellScriptBin "tmux-scratch" ''
        set -euo pipefail

        scratch_session="scratch"

        get_window_option() {
          tmux show-options -wqv -t "$1" "$2" 2>/dev/null || true
        }

        sanitize_name() {
          local raw="$1"
          if [ -z "$raw" ]; then
            printf 'scratch'
            return
          fi
          printf '%s' "$raw" | tr -c '[:alnum:]_-' '-'
        }

        enter_scratch() {
          local caller_session_id caller_session_name pane_path label_suffix label scratch_window
          caller_session_id=$(tmux display-message -p '#{session_id}')
          caller_session_name=$(tmux display-message -p '#{session_name}')
          pane_path=$(tmux display-message -p '#{pane_current_path}')
          label_suffix=$(sanitize_name "$caller_session_name")
          label="scratch-''${label_suffix}"

          if ! tmux has-session -t "$scratch_session" 2>/dev/null; then
            tmux new-session -ds "$scratch_session" -c "$pane_path" -n "$label"
            scratch_window=$(tmux list-windows -t "$scratch_session" -F '#{window_id}' | tail -n 1)
          else
            scratch_window=$(tmux new-window -P -t "$scratch_session" -F '#{window_id}' -n "$label" -c "$pane_path")
          fi

          tmux set-option -w -t "$scratch_window" '@scratch_source_session_id' "$caller_session_id"
          tmux set-option -w -t "$scratch_window" '@scratch_source_session_name' "$caller_session_name"
          tmux set-option -w -t "$scratch_window" '@scratch_source_path' "$pane_path"

          tmux switch-client -t "$scratch_session"
          tmux select-window -t "$scratch_window"
        }

        pull_scratch() {
          local current_window target_session target_session_id target_session_name
          current_window=$(tmux display-message -p '#{window_id}')
          target_session_id=$(get_window_option "$current_window" '@scratch_source_session_id')
          target_session_name=$(get_window_option "$current_window" '@scratch_source_session_name')

          if [ -z "$target_session_id" ] && [ -z "$target_session_name" ]; then
            tmux display-message 'scratch: current window has no origin session information'
            exit 0
          fi

          target_session=""
          if [ -n "$target_session_id" ] && tmux has-session -t "$target_session_id" 2>/dev/null; then
            target_session="$target_session_id"
          elif [ -n "$target_session_name" ] && tmux has-session -t "$target_session_name" 2>/dev/null; then
            target_session="$target_session_name"
          else
            tmux display-message 'scratch: original session is no longer available'
            exit 0
          fi

          tmux move-window -s "$current_window" -t "$target_session"
          tmux switch-client -t "$target_session"
          tmux select-window -t "$current_window"
        }

        command="enter"
        if [ "$#" -gt 0 ] && [ -n "$1" ]; then
          command="$1"
        fi
        case "$command" in
          enter|open|start)
            enter_scratch
            ;;
          pull|return)
            pull_scratch
            ;;
          *)
            echo "Usage: tmux-scratch [enter|pull]" >&2
            exit 1
            ;;
        esac
      '';

      promoteScript = pkgs.writeShellScriptBin "tmux-promote" ''
        set -euo pipefail

        current_pane=$(tmux display-message -p '#{pane_id}')
        pane_path=$(tmux display-message -p '#{pane_current_path}')
        new_pane=$(tmux new-window -P -F '#{pane_id}' -n 'promoted' -c "''${pane_path}")

        tmux join-pane -s "''${current_pane}" -t "''${new_pane}"
        tmux select-pane -t "''${current_pane}"
        tmux kill-pane -t "''${new_pane}"
      '';

      scratch = lib.getExe' scratchScript "tmux-scratch";
      promote = lib.getExe' promoteScript "tmux-promote";
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
            {
              # https://github.com/nix-community/home-manager/issues/4894
              plugin = power-theme;
              extraConfig = ''
                set -g @tmux_power_theme 'violet'
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

            # Allow tmux to handle floating windows correctly
            set -g detach-on-destroy off  # Don't exit tmux when closing a session
            set -g escape-time 0          # Faster response for keybindings

            ## Keybinds
            # Source conf file
            bind r source-file ~/.config/tmux/tmux.conf

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

            # Scratch session helpers
            bind t run-shell "${scratch} enter"
            bind T run-shell "${scratch} pull"

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
