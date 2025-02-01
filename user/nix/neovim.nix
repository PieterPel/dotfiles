{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    extraPackages = with pkgs; [
      tree-sitter
      ripgrep
      fd
      lua-language-server
    ];

    plugins = with pkgs.vimPlugins; [
      lazy-nvim
      telescope-nvim
      plenary-nvim
    ];

    extraConfig = ''
      set number
      set relativenumber
      syntax on
    '';
  };
}
