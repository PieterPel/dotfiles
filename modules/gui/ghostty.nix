let
  module = "ghostty";
  parent = "gui";
in
{
  flake.modules.homeManager.${module} =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      ghosttyPackage = if pkgs.stdenv.isLinux then pkgs.ghostty else pkgs.emptyDirectory;
      cfg = config.modules.${parent}.${module};
    in
    {
      options.modules.${parent}.${module} = {
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
            background-blur = 20;
            command = lib.getExe pkgs.fish;
          };
        };
        home.file = lib.mkIf pkgs.stdenv.isDarwin {
          "Library/Application Support/com.mitchellh.ghostty/config" = {
            source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/ghostty/config";
          };
        };
      };
    };
}
