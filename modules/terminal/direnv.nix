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
        };

        programs.fish = {
          enable = true;
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
