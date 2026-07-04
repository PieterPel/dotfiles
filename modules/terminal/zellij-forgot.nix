let
  parent = "terminal";
  module = "zellij-forgot";
in
{
  flake.modules.homeManager.${module} =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.modules.${parent}.${module};
      keybinds = pkgs.writeShellScriptBin "zellij-keybinds" ''
        ${lib.getExe pkgs.bat} --style=plain --language=markdown --paging=never <<'EOF'
        # Zellij Keybindings

        ## Prefix: ctrl+a

        | Key                  | Action           |
        |----------------------|------------------|
        | prefix + d           | split right      |
        | prefix + v           | split down       |
        | prefix + h/j/k/l     | focus pane       |
        | prefix + c           | new tab          |
        | prefix + x           | close pane/tab   |
        | prefix + p           | prev tab         |
        | prefix + n           | next tab         |
        | prefix + w           | tab mode         |
        | prefix + S           | session manager  |
        | prefix + s           | sesh picker      |
        | prefix + y           | yazi             |
        | prefix + g           | lazygit          |
        | prefix + alt+h/j/k/l | resize pane      |
        | prefix + ?           | this cheat sheet |
        EOF
      '';
    in
    {
      options.modules.${parent}.${module} = {
        enable = lib.mkEnableOption "Enable zellij keybind cheat sheet.";
      };

      config = lib.mkIf (cfg.enable && config.modules.terminal.zellij.enable) {
        xdg.configFile."zellij/config.kdl".text = lib.mkAfter ''
          keybinds {
            tmux {
              bind "?" {
                Run "${lib.getExe keybinds}" { floating true; close_on_exit true; }
                SwitchToMode "Normal";
              }
            }
          }
        '';
      };
    };
}
