{
  flake.modules.homeManager.zellij =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.modules.terminal.zellij;
    in
    {
      options.modules.terminal.zellij = {
        enable = lib.mkEnableOption "Enable Zellij configuration.";
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ pkgs.zellij ];

        xdg.configFile."zellij/config.kdl".text = ''
          // UI
          theme "catppuccin-mocha"
          default_layout "compact"
          pane_frames false
          simplified_ui false
          mouse_mode true
          scroll_buffer_size 10000
          copy_on_select true

          // Session
          session_serialization true

          keybinds clear-defaults=true {
            normal {
              // Prefix: Ctrl-a (mirrors tmux setup)
              bind "Ctrl a" { SwitchToMode "tmux"; }
            }

            tmux {
              bind "Ctrl a" { Write 1; SwitchToMode "Normal"; }
              bind "Esc"    { SwitchToMode "Normal"; }

              // Splits (matches tmux: d=horizontal, v=vertical)
              bind "d" { NewPane "Right"; SwitchToMode "Normal"; }
              bind "v" { NewPane "Down"; SwitchToMode "Normal"; }

              // Navigation (hjkl)
              bind "h" { MoveFocus "Left";  SwitchToMode "Normal"; }
              bind "j" { MoveFocus "Down";  SwitchToMode "Normal"; }
              bind "k" { MoveFocus "Up";    SwitchToMode "Normal"; }
              bind "l" { MoveFocus "Right"; SwitchToMode "Normal"; }

              // Windows / tabs
              bind "c" { NewTab; SwitchToMode "Normal"; }
              bind "x" { CloseFocus; SwitchToMode "Normal"; }
              bind "p" { GoToPreviousTab; SwitchToMode "Normal"; }
              bind "n" { GoToNextTab; SwitchToMode "Normal"; }
              bind "w" { SwitchToMode "Tab"; }

              // Sessions (S = built-in picker; s = sesh picker via sesh.nix)
              bind "S" { SwitchToMode "Session"; }

              // Resize
              bind "M-h" { Resize "Increase Left";  SwitchToMode "Normal"; }
              bind "M-j" { Resize "Increase Down";  SwitchToMode "Normal"; }
              bind "M-k" { Resize "Increase Up";    SwitchToMode "Normal"; }
              bind "M-l" { Resize "Increase Right"; SwitchToMode "Normal"; }
            }

            shared_except "normal" "locked" {
              bind "Esc" { SwitchToMode "Normal"; }
            }

            locked {
              bind "Ctrl g" { SwitchToMode "Normal"; }
            }
          }
        '';
      };
    };
}
