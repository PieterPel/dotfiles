{ config
, pkgs
, ...
}:

# NOTE: these settings must be shared by both nix-darwin and nixos
let
  corePackages = import ./packages.nix { inherit pkgs; };
in
{
  environment.systemPackages = corePackages.packages;
  programs.firefox.enable = true;

  # Enable fish so it can be used as the default shell.
  programs.fish.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  networking.hostName = config.hostname;

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";
}
