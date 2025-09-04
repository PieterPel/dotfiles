{ config, lib, ... }:

let
  cfg = config.modules.core.nix;
in
{
  options.modules.core.nix = {
    enable = lib.mkEnableOption "Enable nix module";
  };

  config = lib.mkIf cfg.enable {

    # Binary caches
    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      substituters = [
        "https://cache.nixos.org/"
        "https://devenv.cachix.org"
        "https://nixos-raspberrypi.cachix.org"
      ];

      trusted-public-keys = [
        "devenv.cachix.org-1:LsUwPwJv9iW7NLhFhJPDGFkqpT7LhNkpIws88soZV/M="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
      ];

      trusted-users = [
        "@wheel"
      ];
    };

    # Automatic cleanup
    nix.gc = {
      automatic = true;
      options = "--delete-older-than 10d";
    };
    nix.optimise.automatic = true;
  };
}
