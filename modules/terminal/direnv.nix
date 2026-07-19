{
  flake.modules.homeManager.direnv =
    { config, lib, ... }:
    let
      cfg = config.modules.terminal.direnv;
      asyncDirenv = ''
        function __direnv_export_eval --on-event fish_prompt
            set -l prev_status $status
            if set -q __direnv_async_file
                if test -f $__direnv_async_file
                    source $__direnv_async_file 2>/dev/null
                end
                rm -f $__direnv_async_file
                set -e __direnv_async_file
            end
            set -g __direnv_async_file (mktemp /tmp/direnv.XXXXXXXXXX)
            command direnv export fish >$__direnv_async_file 2>/dev/null </dev/null &
            disown
            return $prev_status
        end

        function __direnv_cd_hook --on-variable PWD
            set -g __direnv_async_file (mktemp /tmp/direnv.XXXXXXXXXX)
            command direnv export fish >$__direnv_async_file 2>/dev/null </dev/null &
            disown
        end
      '';
      _ = asyncDirenv; # NOTE: was too buggy but keeping for future reference
    in
    {
      options.modules.terminal.direnv = {
        enable = lib.mkEnableOption "Enable direnv configuration.";
      };

      config = lib.mkIf cfg.enable {
        programs.direnv = {
          enable = true;
          nix-direnv.enable = true;
          enableFishIntegration = false; # replaced by async hook below
          silent = true;
          config = {
            global = {
              warn_timeout = "0s";
            };
          };
        };

        programs.fish = {
          enable = true;

          # Async direnv hook. enableFishIntegration=false prevents the default
          # sync hook from being installed, so this is the only implementation.
          # On each prompt: source the queued result, then start the next bg export.
          # On cd: start a bg export immediately so it's ready by the next prompt.
          interactiveShellInit = ""; # NOTE: see asyndDirenv above

          functions = {
            # 1. The "Space Hunter" - Your command fixed for Fish syntax
            nix-direnv-list-bloat = {
              description = "List all direnv roots and their total closure size";
              body = ''
                nix-store --gc --print-roots | awk '/direnv/ {print $1}' | while read -l root
                    set -l target (readlink -f "$root")
                    set -l size (nix path-info -sh "$target" 2>/dev/null | awk '{print $2}')
                    if test -z "$size"
                        set size "0B"
                    end
                    printf "%10s | %s\n" "$size" "$root"
                end | sort -h
              '';
            };

            # 2. The "Janitor" - Safely breaks the links so GC can actually work
            nix-direnv-clean-all = {
              description = "Wipe all local direnv caches to allow garbage collection";
              body = ''
                echo "Breaking indirect GC roots in project folders..."
                # Find and remove all .direnv directories in your home folder
                find $HOME/home -name ".direnv" -type d -prune -exec rm -rf {} +

                echo "Clearing Nix evaluation cache..."
                rm -rf $HOME/.cache/nix

                echo "Running Garbage Collector..."
                sudo nix-collect-garbage -d

                echo "Done. Your projects will re-evaluate next time you enter them."
              '';
            };
          };

          shellAliases = {
            "ndl" = "nix-direnv-list-bloat";
            "ndc" = "nix-direnv-clean-all";
          };
        };

        # Prevents nix-direnv from keeping environments alive forever
        home.sessionVariables = {
          NIX_DIRENV_MAX_AGE = "7d";
        };
      };
    };
}
