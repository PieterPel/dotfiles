{
  flake.modules.homeManager.direnv = { config, lib, ... }:
    let
      cfg = config.modules.terminal.direnv;
    in
    {
      options.modules.terminal.direnv = {
        enable = lib.mkEnableOption "Enable direnv configuration.";
      };

      config = lib.mkIf cfg.enable {
        programs.direnv = {
          enable = true;
          nix-direnv.enable = true;
        };
      };
    };
}
