{ ... }:
let
  homeManagerWslModule = { config, lib, ... }:
    let
      cfg = config.modules.profiles.wsl;
    in
    {
      options.modules.profiles.wsl = {
        enable = lib.mkEnableOption "Enable WSL profile for Home Manager";
      };

      config = lib.mkIf cfg.enable {
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
      };
    };
in
{
  flake.modules.homeManager.wsl = homeManagerWslModule;
}
