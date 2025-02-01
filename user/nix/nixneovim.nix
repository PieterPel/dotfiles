{ config, pkgs, ... }:

{
  programs.nixneovim = {
    enable = true;
    defaultEditor = true;

    # to install plugins just activate their modules
    plugins = {
      lspconfig = {
        enable = true;
        servers = {
          hls.enable = true;
          rust-analyzer.enable = true;
        };
      };
      treesitter = {
        enable = true;
        indent = true;
      };
      mini = {
        enable = true;
        ai.enable = true;
        jump.enable = true;
      };
    };

   options = {
     number = true;
     relativeNumber = true;
   };

  };
}
