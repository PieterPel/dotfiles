{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./nixvim/default.nix
    ./direnv.nix
    ./fish.nix
    ./tmux.nix
    ./git.nix
    inputs.nixvim.homeManagerModules.nixvim
  ];

  home.packages = with pkgs; [
    # Verstion control
    git
    pre-commit
    lazygit

    # Nix
    nh

    # Languages
    python3
    cargo
    gcc
    nodejs_22
    cabal-install
    ghc

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
    eza

    # AI
    gemini-cli
  ];

  programs.zoxide = {
    enable = true;
    options = [
      "--cmd cd"
    ];
  };

  programs.btop.enable = true;
}
