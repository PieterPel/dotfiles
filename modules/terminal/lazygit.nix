let
  module = "lazygit";
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
      lazygitBin = lib.getExe pkgs.lazygit;
    in
    {
      options.modules.terminal.${module} = {
        enable = lib.mkEnableOption "Enable ${module}.";
      };
      config = lib.mkIf cfg.enable (lib.mkMerge [
        {
          programs.lazygit.enable = true;

          programs.tmux.extraConfig = lib.mkAfter ''
            bind g display-popup -E -w 80% -h 80% "${lazygitBin}"
          '';
        }

        (lib.mkIf config.modules.terminal.zellij.enable {
          xdg.configFile."zellij/config.kdl".text = lib.mkAfter ''
            keybinds {
              tmux {
                bind "g" {
                  Run "${lazygitBin}" { floating true; close_on_exit true; }
                  SwitchToMode "Normal";
                }
              }
            }
          '';
        })
      ]);
    };
}
