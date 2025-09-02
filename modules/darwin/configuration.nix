{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.modules.darwin.configuration;
in
{
  options.modules.darwin.configuration = {
    enable = lib.mkEnableOption "Enable darwin configuration";
  };

  config = lib.mkIf cfg.enable {
    #  NOTE: Your can find all available options in:
    #    https://daiderd.com/nix-darwin/manual/index.html

    # Add ability to used TouchID for sudo authentication
    security.pam.services.sudo_local.touchIdAuth = true;

    packages = with pkgs; [
      sketchybar
      aerospace
      jankyborders
      raycast
    ];
  };
}
