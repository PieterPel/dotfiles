{
  flake.modules.homeManager.direnv =
    { config, lib, ... }:
    let
      cfg = config.modules.terminal.direnv;
    in
    {
      options.modules.terminal.direnv = {
        enable = lib.mkEnableOption "Enable direnv configuration.";
      };

      config = lib.mkIf cfg.enable {
        programs.direnv = {
          enable = true;
          nix-direnv.enable = true;
          # Suppress all direnv output (loading messages, env diff on reload)
          silent = true;
          config = {
            global = {
              # Default is 5s which is too aggressive for Nix env evaluations
              warn_timeout = "0s";
            };
          };
        };

        programs.fish = {
          enable = true;

          # Override direnv's synchronous fish hook with a non-blocking async version.
          #
          # direnv's default `__direnv_export_eval` runs `direnv export fish | source`
          # synchronously on every fish_prompt event. With a warm nix-direnv cache this
          # is only ~8ms, but on a cache miss (first enter, flake.lock change) it blocks
          # the terminal for the full Nix evaluation — potentially 30s+.
          #
          # This replacement runs the export in the background and sources the result on
          # the *next* prompt render. With a warm cache the job finishes in <50ms, so by
          # the time you type your next command the env is already in place. On a cold
          # cache the shell stays responsive and the env silently loads when Nix is done.
          #
          # Trade-off: one-prompt delay before env vars are visible. In practice this is
          # imperceptible because the bg job almost always finishes before you type again.
          interactiveShellInit = lib.mkOrder 9999 ''
            # On each prompt: source the result queued by the previous bg job, then queue the next one.
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

            # On cd: kick off a bg export (result sourced on next prompt).
            function __direnv_cd_hook --on-variable PWD
                set -g __direnv_async_file (mktemp /tmp/direnv.XXXXXXXXXX)
                command direnv export fish >$__direnv_async_file 2>/dev/null </dev/null &
                disown
            end

            # Drop direnv's synchronous preexec re-run; just clean up the cd hook.
            function __direnv_export_eval_2 --on-event fish_preexec
                functions --erase __direnv_cd_hook
            end
          '';

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
