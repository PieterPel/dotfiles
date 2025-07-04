{
  config,
  pkgs,
  inputs,
  ...
}:

{
  programs.tmux = {
    enable = true;
    shell = "${pkgs.fish}/bin/fish";
    terminal = "tmux-256color";
    plugins = with pkgs; [
      tmuxPlugins.better-mouse-mode
      tmuxPlugins.prefix-highlight
      tmuxPlugins.power-theme
      tmuxPlugins.continuum
    ];
    extraConfig = ''
      set -gu default-command
      set -g default-shell "$SHELL"
      set -g mouse on
    '';
  };
}
