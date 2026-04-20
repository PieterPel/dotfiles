{
  flake.modules.homeManager.git =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.modules.terminal.git;
    in
    {
      options.modules.terminal.git = {
        enable = lib.mkEnableOption "Enable Git configuration.";
      };

      config = lib.mkIf cfg.enable {
        packages = with pkgs; [
          pre-commit
        ];

        programs.gh = {
          enable = true;
        };

        programs.git = {
          enable = true;
          signing.format = null;
          settings = {
            user.name = "Pieter Pel";
            user.email = "pelpieter@gmail.com";
          };
        };
      };
    };
}
