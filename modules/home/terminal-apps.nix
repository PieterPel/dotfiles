{ config
, pkgs
, inputs
, ...
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
    bat
    ripgrep
    eza
    lazysql
    fzf
    silver-searcher
    curlie

    # AI
    gemini-cli
    opencode

    # Containers
    podman-tui
    podman-compose
    dive
    lazydocker

    # Misc
    spotify-player

    # Jujutsu
    jujutsu
    lazyjj
    jjui
  ];

  programs.zoxide = {
    enable = true;
    options = [
      "--cmd cd"
    ];
  };

  programs.btop.enable = true;
}
