{ pkgs
, lib
, config
, ...
}:
let
  username = config.username;
in
{
  # Here you can put stuff that is only needed if home-manager is used standalone
  home.username = username;
  home.homeDirectory = "/home/${username}";

  stylix = {
    base16Scheme = "${pkgs.base16-schemes}/share/themes/purpledream.yaml";
    polarity = "dark";
  };

  programs.nixvim.extraConfigVim = lib.mkAfter ''
    highlight Normal guibg=none ctermbg=none
    highlight NormalNC guibg=none ctermbg=none
    highlight EndOfBuffer guibg=none ctermbg=none
    highlight VertSplit guibg=none ctermbg=none
    highlight StatusLine guibg=none ctermbg=none
    highlight LineNr guibg=none ctermbg=none
    highlight SignColumn guibg=none ctermbg=none
  '';
}
