{
  flake.modules.homeManager.sesh =
    { config
    , pkgs
    , lib
    , ...
    }:
    let
      cfg = config.modules.terminal.sesh;

      sesh = pkgs.lib.getExe pkgs.sesh;
      fzf = pkgs.lib.getExe pkgs.fzf;
      fzf-tmux = pkgs.lib.getExe' pkgs.fzf "fzf-tmux";
      seshKey = "s";

      seshPickerZellij' = pkgs.writeShellScriptBin "sesh-picker-zellij" ''
        target=$(${sesh} list -i | ${fzf} \
          --ansi --no-sort --border-label ' sesh ' --prompt '⚡ ' \
          --header ' ^a all | ^t sessions | ^g configs | ^x zoxide ' \
          --bind 'ctrl-a:change-prompt(⚡ )+reload(${sesh} list -i)' \
          --bind 'ctrl-t:change-prompt(🪟 )+reload(${sesh} list -it)' \
          --bind 'ctrl-g:change-prompt(⚙️ )+reload(${sesh} list -ic)' \
          --bind 'ctrl-x:change-prompt(📁 )+reload(${sesh} list -iz)')

        if [ -n "$target" ]; then
          ${sesh} connect "$(echo "$target" | awk '{print $NF}')"
        fi
      '';
      seshPickerZellij = lib.getExe' seshPickerZellij' "sesh-picker-zellij";

      seshPicker' = pkgs.writeShellScriptBin "sesh-picker" ''
        target=$(${sesh} list -i | ${fzf-tmux} -p 80%,70% \
          --ansi --no-sort --border-label ' sesh ' --prompt '⚡ ' \
          --header ' ^a all | ^t tmux | ^g configs | ^x zoxide ' \
          --bind 'ctrl-a:change-prompt(⚡ )+reload(${sesh} list -i)' \
          --bind 'ctrl-t:change-prompt(🪟 )+reload(${sesh} list -it)' \
          --bind 'ctrl-g:change-prompt(⚙️ )+reload(${sesh} list -ic)' \
          --bind 'ctrl-x:change-prompt(📁 )+reload(${sesh} list -iz)')

        if [ -n "$target" ]; then
          ${sesh} connect "$(echo "$target" | awk '{print $NF}')"
        fi
      '';
      seshPicker = lib.getExe' seshPicker' "sesh-picker";
    in
    {
      options.modules.terminal.sesh = {
        enable = lib.mkEnableOption "Enable Sesh configuration.";
      };

      config = lib.mkIf cfg.enable (lib.mkMerge [
        { programs = {
          sesh = {
            enable = true;
            settings = {
              session = [
                {
                  name = "Downloads";
                  path = "~/Downloads";
                  startup_command = "yazi";
                }
              ];
            };
          };

          fish.shellAbbrs = {
            "${seshKey}" = "${sesh} connect (${sesh} list | ${fzf})";
          };

          tmux.extraConfig = lib.mkAfter ''
            bind s run-shell "${seshPicker}";
          '';

          fzf = {
            enable = true;
            tmux.enableShellIntegration = true;
          };
        }; }

        (lib.mkIf config.modules.terminal.zellij.enable {
          xdg.configFile."zellij/config.kdl".text = lib.mkAfter ''
            keybinds {
              tmux {
                bind "s" {
                  Run "${seshPickerZellij}" { floating true; close_on_exit true; }
                  SwitchToMode "Normal";
                }
              }
            }
          '';
        })
      ]);
    };
}
