{ ...
}:
let
  coreModule = { config, lib, ... }: {
    options.modules.system.configuration = {
      enable = lib.mkEnableOption "Enable core configuration";
    };
    config = lib.mkIf config.modules.system.configuration.enable {
      environment.systemPackages = config.packages;
      environment.shellAliases = config.aliases;
      programs.fish.enable = true;
      nixpkgs.config.allowUnfree = true;
      services.openssh.enable = true;
      networking.hostName = config.hostname;
      time.timeZone = "Europe/Amsterdam";
    };
  };

  nixosModule = { config, lib, ... }: {
    imports = [ coreModule ];
    config = lib.mkIf config.modules.system.configuration.enable {
      environment.sessionVariables = config.envVars;
      security.polkit.enable = true;
      programs.firefox.enable = true;
      nix.gc.dates = "daily";
      services.onedrive.enable = false;
    };
  };

  darwinModule = { config, lib, ... }: {
    imports = [ coreModule ];
    config = lib.mkIf config.modules.system.configuration.enable {
      security.pam.services.sudo_local.touchIdAuth = true;
      nix.gc.interval = { Weekday = 0; Hour = 0; Minute = 0; };
      system.defaults = {
        spaces.spans-displays = true;
        dock.autohide = true;
        NSGlobalDomain._HIHideMenuBar = true;
      };
      services = {
        sketchybar.enable = false;
        jankyborders.enable = false;
      };
      modules.wm.aerospace.profile = "numbered";
      programs.zsh = {
        shellInit = ''
          eval "$(/opt/homebrew/bin/brew shellenv)"
        '';
        enable = true;
      };
      programs.fish = {
        interactiveShellInit = ''
          /opt/homebrew/bin/brew shellenv | source
        '';
      };
      launchd.user.envVariables = {
        PATH = "${config.environment.systemPath}";
      };
    };
  };
in
{
  flake.modules.nixos.configuration = nixosModule;
  flake.modules.darwin.configuration = darwinModule;
}
