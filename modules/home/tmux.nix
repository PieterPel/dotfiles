{ pkgs
, ...
}:

{
  programs.tmux = {
    enable = true;
    shell = "${pkgs.fish}/bin/fish";
    terminal = "tmux-256color";
    baseIndex = 1;
    disableConfirmationPrompt = true;
    keyMode = "vi";
    historyLimit = 10000;
    mouse = true;
    prefix = "C-a";
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
      set -gu default-command
      set -g default-shell "$SHELL"
      set -g mouse on
      set-option -g allow-rename off # Don't rename self-named windows

      ## Keybinds
      # Source conf file
      bind r source-file ~/tmux/tmux.conf

      # Navigation between panes
      bind -n M-h select-pane -L
      bind -n M-l select-pane -R
      bind -n M-k select-pane -U
      bind -n M-j select-pane -D

      # Split panes using | and -
      bind | split-window -h
      bind - split-window -v
      unbind '"'
      unbind %
    '';
  };
}
