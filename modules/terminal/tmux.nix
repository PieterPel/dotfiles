{
  flake.modules.homeManager.tmux =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.modules.terminal.tmux;
      fish = lib.getExe pkgs.fish;

      incubatorScript = pkgs.writeShellScriptBin "tmux-incubator" ''
        WIDTH=$(tmux display-message -p '#{window_width}')
        if [ "$WIDTH" -gt 200 ]; then
          tmux display-popup -E -w 120 -h 80% "fish"
        else
          tmux display-popup -E -w 90% -h 80% "fish"
        fi
      '';

      promoteScript = pkgs.writeShellScriptBin "tmux-promote" ''
        current_pane=$(tmux display-message -p '#P')
        new_window=$(tmux new-window -P -n "promoted")
        tmux join-pane -s "$current_pane" -t "$new_window.0"
        tmux kill-pane -t "$new_window.1"
      '';

      incubator = lib.getExe' incubatorScript "tmux-incubator";
      promote = lib.getExe' promoteScript "tmux-promote";
    in
    {
      options.modules.terminal.tmux = {
        enable = lib.mkEnableOption "Enable Tmux configuration.";
      };

      config = lib.mkIf cfg.enable {
        programs.tmux = {
          enable = true;
          terminal = "tmux-256color";
          baseIndex = 1;
          keyMode = "vi";
          shell = "${pkgs.fish}/bin/fish";
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
          # TODO: some of these alt bindings conflict with aerospace now
          extraConfig = ''
            # General 
            set -gu default-command
            set -g default-shell "$SHELL"
            set-option -g allow-rename off # Don't rename self-named windows
            set-option -g wrap-search on # Go from window N to window 1 

            # Allow tmux to handle floating windows correctly
            set -g detach-on-destroy off  # Don't exit tmux when closing a session
            set -g escape-time 0          # Faster response for keybindings

            ## Keybinds
            # Source conf file
            bind r source-file ~/tmux/tmux.conf

            # Navigation between panes
            bind h select-pane -L
            bind l select-pane -R
            bind k select-pane -U
            bind j select-pane -D

            # Navigation between windows
            bind b previous-window
            bind n next-window

            # Open new windows in current directory
            bind c new-window -c "#{pane_current_path}"

            # Split panes using | and -
            bind d split-window -h -c "#{pane_current_path}"
            bind v split-window -v -c "#{pane_current_path}"
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

            # Custom scripts
            bind n run-shell "${incubator}"
            # Re-bind prefix inside the popup table
            bind-key -T popup C-a switch-client -T popup-prefix
            
            # Bind p to promote within the popup-prefix table
            bind-key -T popup-prefix p run-shell "${promote}"
            bind p run-shell "${promote}"
          '';
        };
      };
    };
}
