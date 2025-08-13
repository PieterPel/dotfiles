{ config
, lib
, pkgs
, inputs
, ...
}:
{
  imports = [
    ../programs/nixvim
    ../programs/direnv.nix
    ../programs/fish.nix
    ../programs/tmux.nix
    ../programs/git.nix
    ../programs/starship.nix
    inputs.nixvim.homeManagerModules.nixvim
  ];

  config = lib.mkIf config.enableTerminalApps {
    modules.programs = {
      direnv.enable = true;
      fish.enable = true;
      tmux.enable = true;
      git.enable = true;
      starship.enable = true;
      nixvim.enable = true;
    };

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
      viu

      # CLI tools
      bat
      ripgrep
      eza
      lazysql
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
  };
}
