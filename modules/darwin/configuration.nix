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

    system.defaults = {
      # Make all displays have the same space
      spaces.spans-displays = true;

      # Hide the dock
      dock.autohide = true;
    };

    services = {
      sketchybar = {
        # NOTE: nomen est omen
        enable = false;
      };
      aerospace = {
        enable = true;
        settings = builtins.fromTOML (builtins.readFile ./aerospace.toml);
      };
      jankyborders = {
        # NOTE: ugly, laggy and unneccesary; maybe try configuring in future
        enable = false;
      };
    };

    programs.zsh.enable = true;

    launchd.user.envVariables = {
      # Make sure GUI apps launched from Spotlight/Dock
      # also get the nix-darwin environment
      PATH = "${config.environment.systemPath}";
    };

    packages = with pkgs; [
    ];
  };
}
