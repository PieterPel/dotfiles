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

      # Session numbering + current-session highlight only. Claude/Codex state
      # is reported by tmux-agent-status off hooks now, so this no longer walks
      # the process tree -- which is what made it cost ~250ms per redraw.
      sessionStatusScript = pkgs.writeShellScriptBin "tmux-session-status" ''
        set -euo pipefail

        sessions=($(tmux list-sessions -F '#S' 2>/dev/null))
        current="''${TMUX_SESSION_OVERRIDE:-$(tmux display-message -p '#S')}"
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

          output+="#[fg=$seg_fg,bg=$seg_bg,$seg_bold] $num $s "

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

      sessionSwitchHookScript = pkgs.writeShellScriptBin "tmux-session-switch-hook" ''
        session="''${1:-}"
        bar=$(TMUX_SESSION_OVERRIDE="$session" ${sessionStatus} 2>/dev/null)
        tmux set-option -gq @session_status_bar "$bar"
        tmux refresh-client -S
      '';

      sessionSwitchHook = lib.getExe' sessionSwitchHookScript "tmux-session-switch-hook";

      # Upstream ships no .claude-plugin manifest (its README tells you to
      # hand-edit ~/.claude/settings.json, which is a read-only store symlink
      # here). We synthesise one in postInstall so the hooks register through
      # programs.claude-code.plugins instead -- zellij.nix already owns
      # settings.hooks, and a second definition of those keys would conflict.
      agentStatusPlugin = pkgs.tmuxPlugins.mkTmuxPlugin {
        pluginName = "tmux-agent-status";
        version = "unstable-2026-07-31";
        src = pkgs.fetchFromGitHub {
          owner = "samleeney";
          repo = "tmux-agent-status";
          rev = "a323f10eedabc499fc1c8d4e1c73a564c6e3ae70";
          hash = "sha256-JMZt88rZkvLYRXZriWDeY1wZtqD8t/wawcIG62nm9X4=";
        };
        rtpFilePath = "tmux-agent-status.tmux";
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postInstall = ''
          dir=$out/share/tmux-plugins/tmux-agent-status

          # Some scripts ship non-executable and patchShebangs skips those, so
          # chmod first. macOS /bin/bash is 3.2 and the plugin needs >= 4; with
          # no Homebrew bash on this machine its own lookup would just fail.
          chmod +x $dir/tmux-agent-status.tmux $dir/scripts/*.sh $dir/hooks/*.sh
          patchShebangs $dir/tmux-agent-status.tmux $dir/scripts $dir/hooks

          # HANG FIX. Upstream hooks daemon-monitor.sh onto session-created with
          # a blocking `run-shell`, and that script ends with `( <infinite
          # loop> ) &` -- the backgrounded subshell inherits stdout, so tmux
          # waits on a pipe that never closes and *every new session hangs
          # forever*. It only shows up when the monitor pid file is missing or
          # stale (otherwise the script exits early), which makes it a race
          # rather than a reliable failure. Fix both ends: detach the hook, and
          # close the inherited fds in the script itself.
          sed -i "s|run-shell '\$CURRENT_DIR/scripts/daemon-monitor.sh'|run-shell -b '\$CURRENT_DIR/scripts/daemon-monitor.sh'|" \
            $dir/tmux-agent-status.tmux
          sed -i 's|^) &$|) >/dev/null 2>\&1 \&|' $dir/scripts/daemon-monitor.sh

          # Same bug one level up: the entrypoint launches the collector with a
          # bare `&`, and the entrypoint itself is sourced by a blocking
          # `run-shell`, so the collector's inherited stdout wedges tmux at
          # config load too.
          sed -i 's|^"\$CURRENT_DIR/scripts/sidebar-collector.sh" &$|"$CURRENT_DIR/scripts/sidebar-collector.sh" >/dev/null 2>\&1 \&|' \
            $dir/tmux-agent-status.tmux

          # ATTRIBUTION FIX. get_tmux_session runs `tmux display-message -p
          # '#{session_name}'` with no target, which resolves against the
          # *attached client's* session rather than the pane the hook fired in.
          # The pane half of the key comes from $TMUX_PANE and is correct, so an
          # agent in session B reporting while you look at session A writes
          # A_<pane-of-B>. collect_status_agents then filters panes against that
          # session's live panes, does not find it, and drops the agent -- hence
          # both "statuses are wrong" and "agents don't show up". Target the pane
          # explicitly; fall back to the old behaviour when TMUX_PANE is unset.
          substituteInPlace $dir/hooks/better-hook.sh \
            --replace-fail \
              "tmux display-message -p '#{session_name}' 2>/dev/null" \
              "tmux display-message ''${TMUX_PANE:+-t \"$TMUX_PANE\"} -p '#{session_name}' 2>/dev/null"

          # after-kill-window and after-switch-client are not hook names in tmux
          # 3.7b, so upstream's entrypoint prints "invalid option" twice on every
          # load. Both are redundant -- the sidebar already refreshes on
          # client-attached, client-session-changed, after-select-window,
          # session-window-changed and window-pane-changed. Must run BEFORE the
          # wrap loop below, or it edits the generated wrapper instead.
          sed -i -e '/after-kill-window/d' -e '/after-switch-client/d' \
            $dir/tmux-agent-status.tmux

          # scripts/lib/*.sh are sourced, not executed -- wrapping them would
          # break the `source` calls, so only wrap what gets invoked directly.
          for f in $dir/tmux-agent-status.tmux $dir/scripts/*.sh $dir/hooks/*.sh; do
            [ -f "$f" ] || continue
            wrapProgram "$f" --prefix PATH : ${
              lib.makeBinPath [
                pkgs.bashInteractive
                pkgs.tmux
                pkgs.jq
                pkgs.fzf
                pkgs.gnused
                pkgs.gawk
                pkgs.coreutils
              ]
            }
          done

          mkdir -p $dir/.claude-plugin
          cat > $dir/.claude-plugin/plugin.json <<'EOF'
          ${builtins.toJSON {
            name = "tmux-agent-status";
            version = "0.1.0";
            description = "Report Claude Code agent state to the tmux-agent-status status line and sidebar";
            repository = "https://github.com/samleeney/tmux-agent-status";
          }}
          EOF

          cat > $dir/hooks/hooks.json <<'EOF'
          ${builtins.toJSON {
            hooks = lib.genAttrs
              [
                "UserPromptSubmit"
                "PreToolUse"
                "Stop"
                "Notification"
              ]
              (event: [
                {
                  matcher = "";
                  hooks = [
                    {
                      type = "command";
                      command = ''"''${CLAUDE_PLUGIN_ROOT}/hooks/better-hook.sh" ${event}'';
                    }
                  ];
                }
              ]);
          }}
          EOF
        '';
      };

      # Precomputes the status with the target session highlighted BEFORE switching,
      # so the variable is ready the instant tmux redraws. No #() async lag.
      sessionSwitchToScript = pkgs.writeShellScriptBin "tmux-session-switch-to" ''
        n="''${1:-}"
        target=$(tmux list-sessions -F '#S' | sed -n "''${n}p")
        [ -z "$target" ] && exit 0
        bar=$(TMUX_SESSION_OVERRIDE="$target" ${sessionStatus} 2>/dev/null)
        tmux set-option -gq @session_status_bar "$bar"
        tmux switch-client -t "$target"
        tmux refresh-client -S
      '';

      sessionSwitchTo = lib.getExe' sessionSwitchToScript "tmux-session-switch-to";

    in
    {
      options.modules.terminal.tmux = {
        enable = lib.mkEnableOption "Enable Tmux configuration.";
      };

      config = lib.mkIf cfg.enable {
        # Expose the status hook at a stable path, the same way the notify hook
        # is wired. `programs.claude-code.plugins` does NOT work for this: it
        # only symlinks the directory into ~/.claude/skills/, and Claude Code
        # does not read hooks/hooks.json from a skills-directory plugin -- the
        # generated wrapper carries no --plugin-dir argument at all. Verified by
        # running a fresh session inside a tmux pane and watching
        # ~/.cache/tmux-agent-status/panes/ stay empty.
        #
        # The consumer is claude-settings.json, which is hand-maintained and so
        # cannot carry a /nix/store path (it would rot on GC). It references
        # $HOME/.claude/hooks/tmux-agent-status; nix owns what sits there.
        home.file.".claude/hooks/tmux-agent-status" = {
          executable = true;
          source = pkgs.writeShellScript "tmux-agent-status-hook" ''
            exec ${agentStatusPlugin}/share/tmux-plugins/tmux-agent-status/hooks/better-hook.sh "$@"
          '';
        };

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
              plugin = agentStatusPlugin;
              # Defaults collide with four existing binds: o (tmux-promote),
              # p (previous-window), N (switch-client -n), W (choose-tree).
              extraConfig = ''
                set -g @agent-status-key 'S'
                set -g @agent-sidebar-key 'b'
                set -g @agent-park-key 'K'
                set -g @agent-next-done-key 'J'
                set -g @agent-wait-key 'Z'
                set -g @agent-sidebar-width '42'
                set -g @agent-switcher-default-mode 'tree'
              '';
            }
            {
              plugin = catppuccin;
              extraConfig = ''
                set -g @catppuccin_flavor 'mocha'
                set -g @catppuccin_status_background '#1e1e2e'
                set -g @catppuccin_window_status_style 'slanted'
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
              # The agent summary must contain the literal "status-line.sh" --
              # the plugin greps status-right for it and only auto-appends when
              # absent, so placing it here keeps ordering ours and avoids a
              # duplicate being tacked on the end.
              set -g status-right "#(${agentStatusPlugin}/share/tmux-plugins/tmux-agent-status/scripts/status-line.sh) #(${gitStatus} \"#{pane_current_path}\")"
              set -g status-right-length 150

              # Override catppuccin's mauve accent to Rebels purple
              set -g @thm_mauve '#6A18D1'

              # format[0] (bottom): window tabs; tmux 3.6 default is empty so set explicitly
              set -g status-format[0] "#[align=left range=left]#{E:status-left}#[norange default]#[list=on align=#{status-justify}]#[list=left-marker]<#[list=right-marker]>#[list=on]#{W:#[range=window|#{window_id} #{E:window-status-style}]#[push-default]#{T:window-status-format}#[pop-default]#[norange default]#{?window_end_flag,,#{window-status-separator}},#[range=window|#{window_id} list=focus #{?#{!=:#{E:window-status-current-style},default},#{E:window-status-current-style},#{E:window-status-style}}]#[push-default]#{T:window-status-current-format}#[pop-default]#[norange default]#{?window_end_flag,,#{window-status-separator}}}#[nolist align=right range=right]#{E:status-right}#[norange default]"

              # format[1] (top): session list — pure tmux variable, no #() at all.
              # It only shows session names/numbers now, which change on
              # create/rename/close, so the hooks below cover every case and
              # nothing needs to run per status-interval.
              set -g status-format[1] "#[bg=#1e1e2e]#{@session_status_bar}"

              # Initialize on startup/reload
              run-shell 'tmux set-option -gq @session_status_bar "$(${sessionStatus} 2>/dev/null)"'

              # Update on session switch, creation, rename and close
              set-hook -g client-session-changed 'run-shell "${sessionSwitchHook} #{session_name}"'
              set-hook -g after-new-session 'run-shell "${sessionSwitchHook} #{session_name}"'
              set-hook -g after-rename-session 'run-shell "${sessionSwitchHook} #{session_name}"'
              set-hook -g session-closed 'run-shell "${sessionSwitchHook}"'
              set-hook -ga after-new-session 'send-keys "nvim" Enter'

              # Jump to session N with Prefix+Shift+N (1-9)
              bind '!' run-shell '${sessionSwitchTo} 1'
              bind '@' run-shell '${sessionSwitchTo} 2'
              bind '#' run-shell '${sessionSwitchTo} 3'
              bind '$' run-shell '${sessionSwitchTo} 4'
              bind '%' run-shell '${sessionSwitchTo} 5'
              bind '^' run-shell '${sessionSwitchTo} 6'
              bind '&' run-shell '${sessionSwitchTo} 7'
              bind '*' run-shell '${sessionSwitchTo} 8'
              bind '(' run-shell '${sessionSwitchTo} 9'

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
