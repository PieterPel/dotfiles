{
  flake.modules.homeManager.ghostty =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      ghosttyPackage = if pkgs.stdenv.isLinux then pkgs.ghostty else pkgs.emptyDirectory;
      cfg = config.modules.gui.kitty;
    in
    {
      options.modules.gui.ghostty = {
        enable = lib.mkEnableOption "Enable Ghostty terminal configuration.";
      };
      config = lib.mkIf cfg.enable {
        programs.ghostty = {
          enable = true;
          package = ghosttyPackage;
          enableFishIntegration = true;
          enableZshIntegration = true;
          settings = {
            background-opacity = 0.8;
            background-blur = true;
            command = lib.getExe pkgs.fish;
          };
        };
      };
    };
}
