flakeArgs: {
  flake.modules.homeManager.nixvim =
    { lib, ... }:
    {
      options.modules.terminal.nixvim = {
        enable = lib.mkEnableOption "Enable nixvim configuration.";
      };
      imports = [
        flakeArgs.inputs.nixvim.homeModules.nixvim
      ];
    };

  flake.modules.standaloneHomeManager.nixvim =
    { config, lib, ... }:
    {
      config = lib.mkIf config.modules.terminal.nixvim.enable {
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
