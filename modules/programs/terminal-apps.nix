{ config
, lib
, pkgs
, ...
}:
{
  config = lib.mkIf config.enableTerminalApps {
    modules.programs = {
      direnv.enable = true;
      tmux.enable = true;
      starship.enable = true;
      nixvim.enable = true;
    };

    packages = with pkgs; [
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

      # Monitoring
      btop
    ];

    programs.lazygit.enable = true;
  };
}
