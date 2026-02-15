let
  module = "amp";
  parent = "terminal";
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
    in
    {
      options.modules.${parent}.${module} = {
        enable = lib.mkEnableOption "Enable ${parent}:${module} configuration.";
      };

      config = lib.mkIf cfg.enable {
        programs.amp = {
          enable = true;
        };
      };
    };
}
