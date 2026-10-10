{ inputs, ... }:
{
  flake.modules.homeManager.werkbord =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.modules.terminal.werkbord;
    in
    {
      options.modules.terminal.werkbord = {
        enable = lib.mkEnableOption "Enable werkbord, one board for assigned work and the coding agents on it.";
      };

      config = lib.mkIf cfg.enable {
        packages = [ inputs.mono.packages.${pkgs.stdenv.hostPlatform.system}.werkbord ];
      };
    };
}
