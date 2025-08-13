{ pkgs
, lib
, config
, ...
}:

let
  cfg = config.modules.programs.fish;
  eza = lib.getExe pkgs.eza;
  nh = lib.getExe pkgs.nh;
in
{
  options.modules.programs.fish = {
    enable = lib.mkEnableOption "Enable Fish shell configuration.";
  };

  config = lib.mkIf cfg.enable {
    programs.fish = {
      enable = true;
      interactiveShellInit = ''
        set fish_greeting # Disable greeting
      '';

      # Define plugins
      plugins = with pkgs.fishPlugins; [
      ];
    };
  };
}
