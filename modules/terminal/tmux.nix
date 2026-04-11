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
          echo "#[fg=magenta] $branch #[fg=cyan][$clean_stats]"
        else
          echo "#[fg=magenta] $branch #[fg=green][clean]"
        fi
      '';

      gitStatus = lib.getExe' gitStatusScript "tmux-git-status";
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
              # https://github.com/nix-community/home-manager/issues/4894
              plugin = power-theme;
              extraConfig = ''
                set -g @tmux_power_theme 'violet'
                set -g @tmux_power_show_date false
                set -g @tmux_power_show_time false
                set -g @tmux_power_user_opts "#(${gitStatus} \"#{pane_current_path}\")"

                set-window-option -g window-status-format " #I:#W "
                set-window-option -g window-status-current-format " #I:#W "
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
            set -g status-interval 5
            # Override tmux-power's status-right so time/date don't reappear.
            set -g status-right "#(${gitStatus} \"#{pane_current_path}\")"
            set -g status-right-length 150

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
