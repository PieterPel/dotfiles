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
        };
      };
    };
}
