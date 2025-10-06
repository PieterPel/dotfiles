{ config, lib, ... }:
{
  flake.homeModules.fish = { lib, config, ... }:
    let
      cfg = config.modules.programs.fish;
    in
    {
      options.modules.programs.fish = {
        enable = lib.mkEnableOption "Enable Fish shell configuration.";
      };

      config = lib.mkIf cfg.enable {
        programs.fish = {
          enable = true;
          interactiveShellInit = ''
            set fish_greeting # Disable greeting
          '';

          # Define plugins
          plugins = [
          ];

          # Define fish functions
          functions = {

            devs = {
              # NOTE: I assume that your tmux windows start at 1 rather than 0
              body = ''
                if not tmux has-session -t dev >/dev/null 2>&1
                  echo "Creating new tmux session: dev"

                  tmux new-session -d -s dev

                  devw dev:1
                end

                # Always attach, whether it was new or already running
                tmux attach-session -t dev
              '';
            };

            devw = {
              # NOTE: this is optimized for 21:9
              body = ''
                set -l target $argv[1]
                if test -z "$target"
                  set target (tmux display-message -p -F '#{session_name}:#{window_index}')
                end

                # Middle pane gets 75% of the horizontal space
                tmux split-window -h -p 75 -t $target 'nvim'

                # From middle pane, make left pane of 33% of 75% which is 25%
                tmux split-window -h -p 33 -t "$target" 'gemini'

                # Focus back on the initial left shell pane
                tmux select-pane -t "$target"
              '';
            };
          };
        };
      };
    };
}