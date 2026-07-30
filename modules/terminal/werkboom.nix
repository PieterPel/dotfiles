{ inputs, ... }:
{
  flake.modules.homeManager.werkboom =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.modules.terminal.werkboom;
    in
    {
      options.modules.terminal.werkboom = {
        enable = lib.mkEnableOption "Enable werkboom worktree orchestration CLI.";
      };

      config = lib.mkIf cfg.enable {
        packages = [ inputs.mono.packages.${pkgs.stdenv.hostPlatform.system}.werkboom ];
      };
    };
}
