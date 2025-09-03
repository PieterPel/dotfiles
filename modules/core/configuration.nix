{ config
, lib
, ...
}:

# NOTE: these settings must be shared by both nix-darwin and nixos
let
  cfg = config.modules.core.configuration;
in
{
  options.modules.core.configuration = {
    enable = lib.mkEnableOption "Enable core configuration";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = config.packages;
    environment.shellAliases = config.aliases;

    # programs.firefox.enable = true; # TODO: move to nixos

    # Enable fish so it can be used as the default shell.
    programs.fish.enable = true;

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    # Enable the OpenSSH daemon.
    services.openssh.enable = true;

    networking.hostName = config.hostname;

    # Set your time zone.
    time.timeZone = "Europe/Amsterdam";
  };
}
