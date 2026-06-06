{
  flake.modules.homeManager.yazi =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.modules.terminal.yazi;
      yazi-tmux-launcher' = pkgs.writeShellScriptBin "yazi-tmux-launcher" ''
        tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
        ${pkgs.yazi}/bin/yazi "$@" --cwd-file="$tmp"
        if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
            ${pkgs.tmux}/bin/tmux new-window -c "$cwd"
        fi
        rm -f -- "$tmp"
      '';
      yazi-tmux-launcher = lib.getExe' yazi-tmux-launcher' "yazi-tmux-launcher";
    in
    {
      options.modules.terminal.yazi = {
        enable = lib.mkEnableOption "Enable Yazi configuration.";
      };

      config = lib.mkIf cfg.enable (lib.mkMerge [
        {
        programs.yazi = {
          enable = true;
          shellWrapperName = "yy";
          enableZshIntegration = true;
          enableFishIntegration = true;
          settings = {
            opener = {
              edit = [
                {
                  run = ''nvim "$@"'';
                  block = true;
                }
              ];
              view = [{ run = ''${pkgs.kitty}/bin/kitty +kitten icat "$@"''; }]; # Preview image in Kitty
            };
            # Also ensure the 'open' section points to this 'edit' opener
            open = {
              rules = [
                {
                  name = "*.{png,jpg,jpeg,gif,webp}";
                  use = "view";
                } # Use the viewer for images
                {
                  name = "*";
                  use = "edit";
                }
              ];
            };
          };
        };

        programs.tmux = {
          extraConfig = lib.mkAfter ''
            # 'Prefix + y' opens the Yazi project launcher in a popup
            bind y display-popup -w 80% -h 80% "${yazi-tmux-launcher}"
          '';
        };
        }

        (lib.mkIf config.modules.terminal.zellij.enable {
          xdg.configFile."zellij/config.kdl".text = lib.mkAfter ''
            keybinds {
              tmux {
                bind "y" {
                  Run "${lib.getExe pkgs.yazi}" { floating true; close_on_exit true; }
                  SwitchToMode "Normal";
                }
              }
            }
          '';
        })
      ]);
    };
}
