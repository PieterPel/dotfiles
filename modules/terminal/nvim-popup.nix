{
  flake.modules.homeManager.nvim-popup =
    { config
    , lib
    , ...
    }:
    {
      options.modules.terminal.nvim-popup = {
        enable = lib.mkEnableOption "Enable nvim popup binding.";
      };

      config = lib.mkIf config.modules.terminal.nvim-popup.enable {
        programs.tmux.extraConfig = lib.mkAfter ''
          # 'Prefix + e' opens nvim in a popup rooted at $HOME/home
          bind e display-popup -E -w 90% -h 90% -d "$HOME/home" "${lib.getExe config.programs.nixvim.finalPackage}"
        '';
      };
    };
}
