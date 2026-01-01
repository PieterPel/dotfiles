{
  flake.modules.homeManager.zed =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.modules.gui.zed;
    in
    {
      options.modules.gui.zed = {
        enable = lib.mkEnableOption "Enable Zed editor configuration.";
      };

      config = lib.mkIf cfg.enable {
        packages = with pkgs; ([
          # There is a home-manager module but it sucks
          zed-editor

          # These are to get LSPs workihg nicely
          rust-analyzer
          ruff
          nil
          basedpyright
        ]);
      };
    };
}
