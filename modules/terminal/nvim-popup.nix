{
  flake.modules.homeManager.nvim-popup =
    { config
    , lib
    , pkgs
    , ...
    }:
    {
      options.modules.terminal.nvim-popup = {
        enable = lib.mkEnableOption "Enable nvim popup binding.";
      };

      config = lib.mkIf config.modules.terminal.nvim-popup.enable {
        programs.tmux.extraConfig = lib.mkAfter ''
          # 'Prefix + e' opens nvim in a popup rooted at $HOME
          bind e display-popup -E -w 90% -h 90% -c "$HOME" "${lib.getExe pkgs.neovim}"
        '';
      };
    };
}
