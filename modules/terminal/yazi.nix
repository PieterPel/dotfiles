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

      config = lib.mkIf cfg.enable (
        lib.mkMerge [
          {
            programs.yazi = {
              enable = true;
              shellWrapperName = "yy";
              enableZshIntegration = true;
              enableFishIntegration = true;
              plugins = {
                git = "${
                  pkgs.fetchFromGitHub {
                    owner = "yazi-rs";
                    repo = "plugins";
                    rev = "56d6277d16479424edf380798cee597a40e5b563";
                    hash = "sha256-Lg3ZKAFE9SJjoIToPJ6gf9vEKUsIxk1dLD63NcL29J4=";
                  }
                }/git.yazi";
              };
              initLua = ''
                require("git"):setup({
                  order = 1500,
                })
              '';
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
                      mime = "image/*";
                      use = "view";
                    }
                    {
                      url = "**";
                      use = "edit";
                    }
                  ];
                };
                plugin = {
                  # Registers the git plugin as a fetcher so gitignored/modified
                  # files get a status indicator instead of looking untracked.
                  prepend_fetchers = [
                    {
                      id = "git";
                      url = "*";
                      run = "git";
                      group = "git";
                    }
                    {
                      id = "git";
                      url = "*/";
                      run = "git";
                      group = "git";
                    }
                  ];
                };
              };
              theme = {
                git = {
                  # Gray out gitignored files instead of hiding them
                  ignored = {
                    fg = "#5c6370";
                  };
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
            modules.terminal.zellij.extraTmuxKeybinds = ''
              bind "y" {
                Run "${lib.getExe pkgs.yazi}" { floating true; close_on_exit true; }
                SwitchToMode "Normal";
              }
            '';
          })
        ]
      );
    };
}
