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

      # werkbord's tmux plugin: dots for every agent's status (werkbord's
      # own, or tmux-orchid's @agent_state for any other), the session row
      # sorted by what needs you, and keys for the board, the sidebar, a
      # task's menu, answering, a picker and wrapping up.
      # Absent from a mono input pinned before it existed.
      tmuxPlugin = inputs.mono.packages.${pkgs.stdenv.hostPlatform.system}.werkbord-tmux or null;
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
        # After tmux.nix's status-right and session row: the plugin adds to
        # the one and replaces the other. From PATH, like Claude's settings:
        # its subcommands are newer than the pinned mono input's binary.
        programs.tmux.extraConfig = lib.mkIf (tmuxPlugin != null) (lib.mkAfter ''
          set -g @werkbord_bin werkbord
          set -g @werkbord_board_session "${cfg.boardSession}"
          set -g @werkbord_sidebar_width "${toString cfg.sidebarWidth}"
          run-shell ${tmuxPlugin}/share/tmux-plugins/werkbord/werkbord.tmux
        '');
        # Claude Code steers toward the board: werkbord's plugin (handoff,
        # inbox, orchestrator, hooks) from mono's marketplace, and the status
        # line, which a plugin can't set. From PATH: these subcommands are
        # newer than the pinned mono input.
        programs.claude-code.settings = {
          extraKnownMarketplaces.mono.source = {
            source = "git";
            url = "https://codeberg.org/PieterPel/mono.git";
          };
          enabledPlugins."werkbord@mono" = true;
          statusLine = {
            type = "command";
            command = "werkbord claude statusline";
            refreshInterval = 5;
          };
        };
        packages = [
          package
        ]
        # Apple's `container`: the VMs werkbord's boxed agents run in.
        ++ lib.optionals pkgs.stdenv.isDarwin [ pkgs.container ];
      };
    };
}
