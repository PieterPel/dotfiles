{
  flake.modules.homeManager.git-session-layout =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.modules.terminal.git-session-layout;

      layoutScript = pkgs.writeShellScriptBin "tmux-git-layout" ''
        set -euo pipefail
        session="$1"
        path="$2"

        cd "$path" 2>/dev/null || exit 0
        git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

        # The board's session is werkbord's own.
        if tmux show-environment -t "=$session" WERKBORD_BOARD >/dev/null 2>&1; then
          exit 0
        fi

        # A werkbord task session: window 1 is the agent (with the board
        # beside it), so the editor and shell come after it.
        if tmux show-environment -t "=$session" WERKBORD_TASK >/dev/null 2>&1; then
          tmux new-window -d -t "=$session:" -n "nvim" -c "$path"
          tmux send-keys -t "=$session:nvim" "nvim ." Enter
          tmux new-window -d -t "=$session:" -n "shell" -c "$path"
          exit 0
        fi

        tmux rename-window -t "$session:1" "nvim"
        tmux send-keys -t "$session:1" "nvim ." Enter

        tmux new-window -t "$session" -n "shell"  -c "$path"

        tmux select-window -t "$session:nvim"
      '';

      layout = lib.getExe' layoutScript "tmux-git-layout";
    in
    {
      options.modules.terminal.git-session-layout = {
        enable = lib.mkEnableOption "Auto-setup windows when opening a session in a git repo.";
      };

      config = lib.mkIf cfg.enable {
        programs.tmux.extraConfig = lib.mkAfter ''
          set-hook -g after-new-session 'run-shell "${layout} #{session_name} #{session_path}"'
        '';
      };
    };
}
