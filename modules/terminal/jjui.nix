let
  parent = "terminal";
  module = "jjui";
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
      jjuiBin = lib.getExe pkgs.jjui;
    in
    {
      options.modules.terminal.${module} = {
        enable = lib.mkEnableOption "Enable ${parent}${module}.";
      };
      config = lib.mkIf cfg.enable {

        programs.jjui = {
          enable = true;
        };

        programs.tmux = {
          extraConfig = lib.mkAfter ''
            bind u display-popup -E -w 80% -h 80% "${jjuiBin}"
          '';
        };
      };
    };
}
