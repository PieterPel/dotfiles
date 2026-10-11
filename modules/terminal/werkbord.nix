{ inputs, ... }:
{
  flake.modules.homeManager.werkbord =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.modules.terminal.werkbord;
      package = inputs.mono.packages.${pkgs.stdenv.hostPlatform.system}.werkbord;
      werkbord = lib.getExe package;

      # The board is a session of its own; `werkbord` started in it runs the
      # board, and WERKBORD_BOARD keeps the after-new-session hooks off it.
      boardScript = pkgs.writeShellScriptBin "werkbord-board" ''
        set -euo pipefail
        if ! tmux has-session -t "=${cfg.boardSession}" 2>/dev/null; then
          tmux new-session -d -s "${cfg.boardSession}" -e WERKBORD_BOARD=1 "${werkbord}"
        fi
        tmux switch-client -t "=${cfg.boardSession}"
      '';

      # The sidebar werkbord puts beside its agents, toggled in any window:
      # werkbord tags its pane, so it's found again by that.
      sidebarScript = pkgs.writeShellScriptBin "werkbord-sidebar-toggle" ''
        set -euo pipefail
        pane=$(tmux list-panes -F '#{pane_id} #{@werkbord_sidebar}' | awk '$2 == "1" { print $1; exit }')
        if [ -n "$pane" ]; then
          tmux kill-pane -t "$pane"
          exit 0
        fi
        task=$(tmux show-environment WERKBORD_TASK 2>/dev/null | sed -n 's/^WERKBORD_TASK=//p')
        new=$(tmux split-window -d -h -b -l ${toString cfg.sidebarWidth} -P -F '#{pane_id}' \
          -c "#{pane_current_path}" -- "${werkbord}" sidebar ''${task:+--task "$task"})
        tmux set-option -p -t "$new" @werkbord_sidebar 1
      '';

      # A dot from the status werkbord stamps on an agent's window (and its
      # task session): working, needs you, ready for review, approved.
      dot = option: lib.concatStrings [
        "#{?${option},"
        "#{?#{==:#{${option}},working},#[fg=#{@thm_blue}]● ,"
        "#{?#{m:needs-*,#{${option}}},#[fg=#{@thm_red}]? ,"
        "#{?#{==:#{${option}},ready-for-review},#[fg=#{@thm_green}]◆ ,"
        "#{?#{==:#{${option}},approved},#[fg=#{@thm_green}]✓ ,}}}},}"
      ];
    in
    {
      options.modules.terminal.werkbord = {
        enable = lib.mkEnableOption "Enable werkbord, one board for assigned work and the coding agents on it.";
        boardSession = lib.mkOption {
          type = lib.types.str;
          default = "werkbord";
          description = "The tmux session the board runs in ([multiplexer] home_session).";
        };
        sidebarWidth = lib.mkOption {
          type = lib.types.ints.positive;
          default = 34;
          description = "Columns of the sidebar the toggle opens ([multiplexer] sidebar_width).";
        };
      };

      config = lib.mkIf cfg.enable {
        packages = [ package ];

        programs.tmux.extraConfig = lib.mkAfter ''
          # werkbord: the board is its own session; every task gets a session
          # with the board as a sidebar beside its agent.
          bind B run-shell "${lib.getExe boardScript}"
          bind J run-shell "${werkbord} next"
          bind b run-shell "${lib.getExe sidebarScript}"

          set -ga status-right " #(${werkbord} status-line --tmux)"

          # tmux.nix shows these on the window tabs and the session row.
          set -g @agent_dot "${dot "@werkbord_status"}"
          set -g @agent_sdot "${dot "@werkbord_status"}"
        '';
      };
    };
}
