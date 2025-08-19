{ pkgs
, config
, lib
, ...
}:

let
  cfg = config.modules.programs.tmux;
  fish = lib.getExe pkgs.fish;
in
{
  options.modules.programs.tmux = {
    enable = lib.mkEnableOption "Enable Tmux configuration.";
  };

  config = lib.mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      terminal = "tmux-256color";
      baseIndex = 1;
      keyMode = "vi";
      historyLimit = 10000;
      plugins = with pkgs.tmuxPlugins; [
        better-mouse-mode
        prefix-highlight
        continuum
        {
          # https://github.com/nix-community/home-manager/issues/4894
          plugin = power-theme;
          extraConfig = ''
            set -g @tmux_power_theme 'violet'
          '';
        }
      ];
      extraConfig = ''
        # General 
        set -gu default-command
        set -g default-shell "$SHELL"
        set-option -g allow-rename off # Don't rename self-named windows
        set-option -g wrap-search on # Go from window N to window 1 

        ## Keybinds
        # Source conf file
        bind r source-file ~/tmux/tmux.conf

        # Navigation between panes
        bind -n M-h select-pane -L
        bind -n M-l select-pane -R
        bind -n M-k select-pane -U
        bind -n M-j select-pane -D

        # Navigation between windows
        bind -n M-[ previous-window
        bind -n M-] next-window

        # Open new windows in current directory
        bind c new-window -c "#{pane_current_path}"

        # Split panes using | and -
        bind | split-window -h -c "#{pane_current_path}"
        bind - split-window -v -c "#{pane_current_path}"
        unbind '"'
        unbind %

        # Set shell to fish
        set-option -g default-shell ${fish}

        ## These have home-manager settings, but no NixOS settings for some reason
        # Disable confirmation prompts (e.g., for killing panes)
        bind-key x kill-pane
        bind-key & kill-window

        # Enable mouse support
        set -g mouse on

        # Change prefix key to Ctrl-a
        unbind C-b
        set -g prefix C-a
        bind C-a send-prefix
      '';
    };
  };
}
