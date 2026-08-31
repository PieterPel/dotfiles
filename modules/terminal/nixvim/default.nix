flakeArgs: {
  flake.modules.homeManager.nixvim =
    { lib, ... }:
    {
      options.modules.terminal.nixvim = {
        enable = lib.mkEnableOption "Enable nixvim configuration.";

        harntDevPath = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "/Users/pieterpel/home/private-projects/harnt.nvim";
          description = ''
            Load harnt.nvim from this local checkout instead of the pinned
            release in extraPlugins. Only for hacking on the plugin itself:
            edits apply on nvim restart with no home-manager switch.

            Leave null everywhere else. Nix doesn't manage the checkout, so a
            host that sets this and then loses the directory gets no plugin.
          '';
        };
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
