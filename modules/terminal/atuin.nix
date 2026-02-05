let
  parent = "terminal";
  module = "atuin";
in
{
  flake.modules.homeManager.${module} =
    { config
    , lib
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
        programs.atuin = {
          enable = true;
          enableFishIntegration = true;
          settings = {
            auto_sync = true;
            sync_frequency = "5m";
            search_mode = "fuzzy";
            filter_mode = "global";
            show_preview = true;
            inline_height = 20;
          };
        };
      };
    };
}
