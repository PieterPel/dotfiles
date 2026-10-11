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
        buildInputs = [
          pkgs.openssl
          pkgs.libgit2
          pkgs.libiconv
        ];
        meta.mainProgram = "claude-tmux";
      };

      # tmux-orchid: an agent-agnostic Bubble Tea dashboard that discovers AI
      # coding agents across every tmux pane (process-tree classification plus
      # pane scraping) and lets you jump to them or spawn new ones. Upstream
      # publishes no release tarball, so it is built from source. The local patch
      # adds first-class `pi` support (detection + spawn entry), which upstream
      # lacks -- see patches/tmux-orchid-pi.patch.
      tmuxOrchid = pkgs.buildGoModule {
        pname = "tmux-orchid";
        version = "unstable-2026-03-18";
        src = pkgs.fetchFromGitHub {
          owner = "FelipeAfonso";
          repo = "tmux-orchid";
          rev = "e116b7ecb5c3094ae260369126630244450c9653";
          hash = "sha256-FWmlEiZSSwyPPZY2lMbSl1EnL2Be6UvrryjgJVH8sCo=";
        };
        vendorHash = "sha256-JDnqDtGoXuPIE0eAlcPcYohD5U9JMI9eSaTdWVv9yio=";
        patches = [ ./patches/tmux-orchid-pi.patch ];
        meta.mainProgram = "tmux-orchid";
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

    in
    {
      options.modules.terminal.tmux = {
        enable = lib.mkEnableOption "Enable Tmux configuration.";
      };

      config = lib.mkIf cfg.enable {
        packages = [ tmuxOrchid ];

        # tmux-orchid keeps its dashboard in a dedicated "orchid" tmux session
        # and, while it is running, installs a prefix keybind to jump back to
        # it. Upstream defaults that keybind to `d`, which this config already
        # uses for split-window -h, so pin it to `g`. Writing the file here
        # (rather than letting the tool write its own default on first run)
        # keeps the choice in nix and reviewable.
        home.file.".config/tmux-orchid/config.toml".text = ''
          # tmux-orchid configuration -- managed by nix (modules/terminal/tmux.nix).
          poll_interval = "2s"

          [session]
          name = "orchid"
          keybind = "g"
          use_prefix = true

          [theme]
          color_scheme = "auto"
        '';

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
              # @agent_dot is an agent's status as a coloured dot, set by the
              # module that knows the agents (werkbord.nix); empty without one.
              # Pure format expansion, no #() per window per redraw.
              extraConfig = ''
                set -g @catppuccin_flavor 'mocha'
                set -g @catppuccin_status_background '#1e1e2e'
                set -g @catppuccin_window_status_style 'slanted'
                set -g @catppuccin_window_current_text '#{E:@agent_dot}#W'
                set -g @catppuccin_window_text '#{E:@agent_dot}#W'
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

              # format[1] (top): session list, rendered natively with #{S:...}.
              #
              # This used to be a bash script whose output was cached in
              # @session_status_bar and refreshed by five hooks. The script
              # existed for one reason: it chained the powerline slants, and
              # drawing a slant that runs into the next segment needs to know
              # the *next* session's colour -- lookahead a format loop cannot do.
              #
              # But catppuccin's own window tabs don't chain either. Each closes
              # its slant against @thm_bg and is separated by a space
              # (window-status-separator is " "). Matching that removes the need
              # for lookahead entirely, so the whole thing collapses to one
              # format string: no script, no cached variable, no hooks, and
              # nothing to go stale -- which also fixes the bar being empty
              # until the first session switch.
              #
              # Colours come from @thm_* rather than hardcoded hexes, so the row
              # follows the theme instead of drifting from it.
              set -g @session_seg_cur '#[fg=#{E:@thm_crust},bg=#{E:@thm_mauve},bold]#{E:@agent_sdot}#{e|+|:#{s|\$||:session_id},1} #{session_name} #[fg=#{E:@thm_mauve},bg=#{E:@thm_bg},nobold]#[default]'
              set -g @session_seg_alt '#[fg=#{E:@thm_fg},bg=#{E:@thm_surface_0}]#{E:@agent_sdot}#{e|+|:#{s|\$||:session_id},1} #{session_name} #[fg=#{E:@thm_surface_0},bg=#{E:@thm_bg}]#[default]'
              set -g status-format[1] "#[bg=#{E:@thm_bg}]#{S:#{?#{==:#{session_name},#{client_session}},#{E:@session_seg_cur},#{E:@session_seg_alt}} }"

              # Not in sessions werkbord makes: typing there would land in
              # an agent's prompt, or press the board's keys.
              set-hook -ga after-new-session 'run-shell "tmux show-environment -t #{q:session_id} WERKBORD_TASK >/dev/null 2>&1 || tmux show-environment -t #{q:session_id} WERKBORD_BOARD >/dev/null 2>&1 || tmux send-keys -t #{q:session_id} nvim Enter"'

              # Jump by the number shown in the row. Displayed number is
              # the session id plus one, so the first session reads 1 and is
              # reachable on shift-1 rather than shift-0 way off on the right.
              bind '!' switch-client -t '$0'
              bind '@' switch-client -t '$1'
              bind '#' switch-client -t '$2'
              bind '$' switch-client -t '$3'
              bind '%' switch-client -t '$4'
              bind '^' switch-client -t '$5'
              bind '&' switch-client -t '$6'
              bind '*' switch-client -t '$7'
              bind '(' switch-client -t '$8'

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

            # Agent dashboard (tmux-orchid): discovers agents across every tmux
            # pane and can spawn new ones. Runs in its own full-screen "orchid"
            # session, so it is a run-shell rather than a popup; re-invoking it
            # just switches back to the running dashboard.
            bind t run-shell "${lib.getExe tmuxOrchid}"
            # Same, but kill the existing dashboard session first.
            bind T run-shell "${lib.getExe tmuxOrchid} --restart"

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
