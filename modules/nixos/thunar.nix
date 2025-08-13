{ pkgs
, config
, lib
, ...
}:

let
  cfg = config.modules.nixos.thunar;
in
{
  options.modules.nixos.thunar = {
    enable = lib.mkEnableOption "Enable thunar module";
  };

  config = lib.mkIf cfg.enable {
    # File manager
    programs.thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
      ];
    };
    services.gvfs.enable = true; # Mount, trash, and other functionalities
    services.tumbler.enable = true; # Thumbnail support for images
  };
}
