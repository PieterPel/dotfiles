{ config, pkgs, inputs, ... }:

{
  imports = [
    ./nixvim.nix
    ./direnv.nix
    ./fish.nix
    ./tmux.nix
    ./git.nix
    inputs.nixvim.homeManagerModules.nixvim
  ];

  home.packages = with pkgs; [
    git
    lazygit

    # Languages
    python3
    cargo
    gcc
    nodejs_22

    # shell
    fish
    oh-my-fish

    # Developing
    tmux
    helix
    devenv

    # File management
    yazi

    # Utilities
    unzip

    # CLI tools
    zoxide
    bat
    rsync
    ripgrep
  ];

  programs.zoxide = {
	enable = true;
	options = [
	  "--cmd cd"
	];
  };

  programs.btop.enable = true;
}
