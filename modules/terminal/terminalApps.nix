let
  module = "terminalApps";
  parent = "terminal";
in
{
  flake.modules.homeManager.${module} =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.modules.${parent}.${module};
    in
    {
      options.modules.${parent}.${module} = {
        enable = lib.mkEnableOption "Enable terminal apps.";
      };
      config = lib.mkIf cfg.enable {
        packages = with pkgs; [
          # Nix
          nh
          statix
          nil
          nixpkgs-fmt

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

          # Command runner
          just
        ];

        programs.btop.enable = true;
      };
    };
}
