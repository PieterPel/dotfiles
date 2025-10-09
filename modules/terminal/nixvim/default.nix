{
  config,
  ...
}:
{
  flake.modules.homeManager.nixvim = {
    imports = [
      config.flake.modules.homeManager."nixvim-binds"
      config.flake.modules.homeManager."nixvim-plugins"
      config.flake.modules.homeManager."nixvim-settings"
    ];
  };

  flake.modules.standaloneHomeManager.nixvim = { config, lib, ... }: {
    config = lib.mkIf config.modules.programs.nixvim.enable {
      programs.nixvim.extraConfigVim = lib.mkAfter ''
        highlight Normal guibg=none ctermbg=none
        highlight NormalNC guibg=none ctermbg=none
        highlight EndOfBuffer guibg=none ctermbg=none
        highlight VertSplit guibg=none ctermbg=none
        highlight StatusLine guibg=none ctermbg=none
        highlight LineNr guibg=none ctermbg=none
        highlight SignColumn guibg=none ctermbg=none
      '';
    };
  };
}
