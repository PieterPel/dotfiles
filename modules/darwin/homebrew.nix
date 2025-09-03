{ config, lib, ... }:

let
  cfg = config.modules.darwin.homebrew;
in
{
  options.modules.darwin.homebrew = {
    enable = lib.mkEnableOption "Enable homebrew  configuration";
  };

  # The packages installed though normal packages are available to all users, and are reproducible across machines, and are rollbackable.
  # But on macOS, it's less stable than homebrew.
  #
  # Related Discussion: https://discourse.nixos.org/t/darwin-again/29331

  # TODO To make this work, homebrew need to be installed manually, see https://brew.sh
  #
  # The apps installed by homebrew are not managed by nix, and not reproducible!
  # But on macOS, homebrew has a much larger selection of apps than nixpkgs, especially for GUI apps!
  config = lib.mkIf cfg.enable {

    homebrew = {
      enable = true;

      onActivation = {
        autoUpdate = false;
        # 'zap': uninstalls all formulae(and related files) not listed here.
        cleanup = "zap";
      };

      taps = [
      ];

      # `brew install`
      brews = [
      ];

      # `brew install --cask`
      casks = [
        "raycast"
        "ghostty"
      ];
    };
  };
}
