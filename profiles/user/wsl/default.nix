{ lib, ... }:
{
  programs.fish = {
    interactiveShellInit = lib.mkAfter ''
      if status is-interactive
          if not set -q TMUX
              tmux attach-session -t default || tmux new-session -s default
          end
          clear
      end
    '';
  };
}
