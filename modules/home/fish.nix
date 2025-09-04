{ pkgs
, lib
, config
, ...
}:

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
      plugins = with pkgs.fishPlugins; [
      ];

      # Define fish functions
      functions = {
        dev = {
          # NOTE: this is optimized for 21:9
          body = ''
            tmux new-session -d -s dev

            # Middle pane gets 80% → left pane keeps 20%
            tmux split-window -h -p 80 -t dev:1 'nvim'

            # From middle pane, make left pane of 25% of 80 % = 20%
            tmux split-window -h -p 25 -t dev:1 'gemini'

            # Focus back on left shell
            tmux select-pane -t dev:1

            tmux attach-session -t dev
          '';
        };
      };
    };
  };
}
