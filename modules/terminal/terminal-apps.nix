{
  flake.modules.homeManager.terminal-apps =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.modules.terminal.terminal-apps;
    in
    {
      options.modules.terminal.terminal-apps = {
        enable = lib.mkEnableOption "Enable terminal apps.";
      };
      config = lib.mkIf cfg.enable {
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
