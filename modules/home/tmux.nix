{
  pkgs,
  ...
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
      power-theme
      continuum
    ];
    extraConfig = ''
      set -gu default-command
      set -g default-shell "$SHELL"
      set -g mouse on
      set -g @tmux_power_theme 'violet'
      set-option -g allow-rename off # Don't rename self-named windows

      ## Keybinds
      # Source conf file
      bind r source-file ~/tmux/tmux.conf

      # Navigation between panes
      bind -n M-Left select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up select-pane -U
      bind -n M-Down select-pane -D

      # Split panes using | and -
      bind | split-window -h
      bind - split-window -v
      unbind '"'
      unbind %
    '';
  };
}
