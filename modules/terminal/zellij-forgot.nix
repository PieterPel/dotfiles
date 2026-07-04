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
      zellijForgotWasm = pkgs.fetchurl {
        url = "https://github.com/karimould/zellij-forgot/releases/download/0.4.2/zellij_forgot.wasm";
        sha256 = "1ns9wjn1ncjapqpp9nn9kyhqydvl0fbnyiavd0lc3gcxa52l269i";
      };
    in
    {
      options.modules.${parent}.${module} = {
        enable = lib.mkEnableOption "Enable zellij-forgot keybinding reference plugin.";
      };

      config = lib.mkIf (cfg.enable && config.modules.terminal.zellij.enable) {
        xdg.configFile."zellij/config.kdl".text = lib.mkAfter ''
          keybinds {
            tmux {
              bind "?" {
                LaunchOrFocusPlugin "file:${zellijForgotWasm}" {
                  floating true
                }
                SwitchToMode "Normal";
              }
            }
          }
        '';
      };
    };
}
