let
  module = "zellij";
in
{
  flake.modules.homeManager.${module} =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.modules.terminal.${module};
    in
    {
      options.modules.terminal.${module} = {
        enable = lib.mkEnableOption "Enable ${module}.";
      };

      config = lib.mkIf cfg.enable {
        programs.zellij = {
          enable = true;
          enableFishIntegration = true;

          settings = {
            # Start in "Locked" mode.
            # This mimics Tmux: keys go to the shell until you press Prefix.
            default_mode = "locked";

            # UI settings: minimize the clutter
            pane_frames = false; # Clean look like Tmux

            keybinds = {
              # 1. LOCKED MODE (Default)
              # Only listen for Ctrl-a
              locked = {
                "bind \"Ctrl a\"" = {
                  SwitchToMode = "Tmux";
                };
                "unbind \"Ctrl b\"" = [ ];
                "unbind \"Ctrl g\"" = [ ]; # Unbind default 'unlock' key
              };

              # 2. TMUX MODE (Prefix Active)
              # This acts like your "Prefix" state.
              tmux = {
                # Press Ctrl-a again to go back to typing (or send literal C-a if you prefer)
                "bind \"Ctrl a\"" = {
                  SwitchToMode = "Locked";
                };
                "bind \"Esc\"" = {
                  SwitchToMode = "Locked";
                };
                "bind \"Enter\"" = {
                  SwitchToMode = "Locked";
                };

                # Navigation
                "bind \"h\"" = {
                  MoveFocus = "Left";
                };
                "bind \"l\"" = {
                  MoveFocus = "Right";
                };
                "bind \"j\"" = {
                  MoveFocus = "Down";
                };
                "bind \"k\"" = {
                  MoveFocus = "Up";
                };

                # Splits
                "bind \"d\"" = {
                  NewPane = "Right";
                  SwitchToMode = "Locked";
                };
                "bind \"v\"" = {
                  NewPane = "Down";
                  SwitchToMode = "Locked";
                };
                "bind \"x\"" = {
                  "CloseFocus; SwitchToMode" = "Locked";
                };

                # 4. POPUPS
                # Lazygit
                "bind \"g\"" = {
                  Run = {
                    _args = [ "lazygit" ];
                    close_on_exit = true;
                    direction = "Floating";
                    x = "5%";
                    y = "5%";
                    width = "90%";
                    height = "90%";
                  };
                  SwitchToMode = "Locked";
                };

                # Yazi
                "bind \"y\"" = {
                  Run = {
                    _args = [ "yazi" ];
                    close_on_exit = true;
                    direction = "Floating";
                    x = "10%";
                    y = "10%";
                    width = "80%";
                    height = "80%";
                  };
                  SwitchToMode = "Locked";
                };
              };
            };
          };
        };
      };
    };
}
