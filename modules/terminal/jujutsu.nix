let
  parent = "terminal";
  module = "jujutsu";
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
        programs.jujutsu = {
          enable = true;

          settings = {
            user = {
              name = "Pieter Pel";
              email = "pelpieter@gmail.com";
            };

            ui = {
              editor = "nvim";
              default-command = "log";
              color = "always";
            };

            revset-aliases = {
              "mine()" = "mine()";
              "pc" = "revsets.log_selectable()";
            };
          };
        };
      };
    };
}
