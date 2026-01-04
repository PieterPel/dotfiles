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
      config = lib.mkIf cfg.enable {

        programs.lazygit = {
          enable = true;
        };

        programs.tmux = {
          extraConfig = lib.mkAfter ''
            bind g display-popup -w 80% -h 80% "${lazygitBin}"
          '';
        };
      };
    };
}
