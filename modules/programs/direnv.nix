{ config
, lib
, ...
}:

let
  cfg = config.modules.programs.direnv;
in
{
  options.modules.programs.direnv = {
    enable = lib.mkEnableOption "Enable direnv configuration.";
  };

  config = lib.mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
