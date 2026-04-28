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

        tmux rename-window -t "$session:1" "code"
        tmux send-keys -t "$session:1" "nvim ." Enter

        tmux new-window -t "$session" -n "shell"  -c "$path"
        tmux new-window -t "$session" -n "dash"   -c "$path" "gh relay"
        tmux new-window -t "$session" -n "claude" -c "$path" "claude"

        tmux select-window -t "$session:code"
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
