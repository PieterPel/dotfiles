{
  flake.modules.homeManager.zoxide =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.modules.terminal.zoxide;
    in
    {
      options.modules.terminal.zoxide = {
        enable = lib.mkEnableOption "Enable zoxide.";
      };
      config = lib.mkIf cfg.enable {

        programs.zoxide = {
          enable = true;
          enableFishIntegration = true;
          options = [
            "--cmd cd"
          ];
        };
      };
    };
}
