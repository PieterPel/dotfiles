{ config, lib, ... }:
{
  flake.darwinModules.configuration = { config, lib, pkgs, ... }:
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

    nix.gc.interval = {
      Weekday = 0;
      Hour = 0;
      Minute = 0;
    };

    system.defaults = {
      # Make all displays have the same space
      spaces.spans-displays = true;

      # Hide the dock
      dock.autohide = true;
    };

    services = {
      sketchybar = {
        # NOTE: Nomen est omen
        enable = false;
      };

      jankyborders = {
        # NOTE: ugly, laggy and unneccesary; maybe try configuring in future
        enable = false;
      };
    };

    modules.darwin.aerospace.profile = "numbered"; # NOTE: apped will require some tweaking

    system.defaults.NSGlobalDomain._HIHideMenuBar = true;

    programs.zsh = {
      shellInit = ''
        eval "$(/opt/homebrew/bin/brew shellenv)"
      '';
      enable = true;
    };
    programs.fish = {
      enable = true;
      interactiveShellInit = ''
        /opt/homebrew/bin/brew shellenv | source
      '';
    };

    launchd.user.envVariables = {
      # Make sure GUI apps launched from Spotlight/Dock
      # also get the nix-darwin environment
      PATH = "${config.environment.systemPath}";
    };

    packages = [
    ];
      };
    };
}
