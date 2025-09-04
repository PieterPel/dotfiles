# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, ... }:

let
  cfg = config.modules.nixos.configuration;
in
{
  options.modules.nixos.configuration = {
    enable = lib.mkEnableOption "Enable nixos configuration";
  };

  config = lib.mkIf cfg.enable {
    environment.sessionVariables = config.envVars;
    # Enable touchpad support (enabled default in most desktopManager).
    # services.xserver.libinput.enable = true;

    # Some programs need SUID wrappers, can be configured further or are
    # started in user sessions.
    # programs.mtr.enable = true;
    # programs.gnupg.agent = {
    #   enable = true;
    #   enableSSHSupport = true;
    # };

    # List services that you want to enable:
    # Onedrive
    # See https://nixos.wiki/wiki/OneDrive for what steps to take
    services.onedrive.enable = false; # enable onedrive in future, now there is a notifcation bug

    # Open ports in the firewall.
    # networking.firewall.allowedTCPPorts = [ ... ];
    # networking.firewall.allowedUDPPorts = [ ... ];
    # Or disable the firewall altogether.
    # networking.firewall.enable = false;

    # Polkit
    security.polkit.enable = true;

    # Firefox
    programs.firefox.enable = true;

    nix.gc.dates = "daily";

  };
}
