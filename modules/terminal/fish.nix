{
  flake.modules.homeManager.fish =
    { lib
    , config
    , pkgs
    , ...
    }:
    let
      cfg = config.modules.terminal.fish;
      jq = lib.getExe pkgs.jq;
    in
    {
      options.modules.terminal.fish = {
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

            # Sync flake.nix with nix-darwin rev
            nix-sync = ''
              # Get the revision from the local nixpkgs registry entry
              set -l rev (nix flake metadata nixpkgs --json | ${jq} -r '.resolved.rev')

              if test -z "$rev"
                set_color red; echo "❌ Could not find a nixpkgs revision in your registry."; set_color normal
                return 1
              end

              echo (set_color blue)"🔄 Syncing project to system revision: "(set_color yellow)"$rev"(set_color normal)

              # Update the lockfile to match your system's exact commit
              nix flake update --override-input nixpkgs "github:NixOS/nixpkgs/$rev"

              set_color green; echo "✅ Done!"; set_color normal
            '';
          };
        };
      };
    };
}
