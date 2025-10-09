{
  flake.modules.homeManager.terminal-apps = { config, lib, pkgs, ... }:
    {
      config = lib.mkIf config.enableTerminalApps {
        modules.programs = {
          direnv.enable = true;
          tmux.enable = true;
          starship.enable = true;
          nixvim.enable = true;
          fish.enable = true;
          git.enable = true;
          ai.enable = true;
        };
        modules.stylix.enable = true;

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

          # Containers
          podman-tui
          podman-compose
          dive
          lazydocker

          # Misc
          # spotify-player

          # Jujutsu
          jujutsu
          jjui

          # Monitoring
          btop
        ];

        programs.btop.enable = true;

        programs.lazygit.enable = true;

        programs.zoxide = {
          enable = true;
          options = [
            "--cmd cd"
          ];
        };
      };
    };
}
