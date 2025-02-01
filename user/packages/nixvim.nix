{config, pkgs, ...}:
{
  programs.nixvim = {
    nixpkgs.config.allowUnfree = true; # nixvim uses its own nixpkgs!!

    enable = true;
    
    opts = {
      number = true;
      relativenumber = true;
      updatetime = 100;
      undofile = true;

      incsearch = true;
      ignorecase = true;
      smartcase = true;

      termguicolors = true;
      spell = false;
      wrap = false;

      tabstop = 4;
      shiftwidth = 4;
      expandtab = true;
      autoindent = true;

      textwidth = 0;
    };

    clipboard = {
      # Use system clipboard
      register = "unnamedplus";
      providers.wl-copy.enable = true;
    };
    
    plugins = {
        # General
        undotree.enable = true; # Virtualize undo history
        mini.enable = true; # Bunch of small utilities
        comment.enable = true; # Better commenting
        cmp.enable = true; # Completion

        # Apearance
        lightline.enable = true; # Pretty bar at the bottom
        web-devicons.enable = true; # Icons
        treesitter.enable = true; # Color code
        treesitter-context.enable = true; # Show context of code

        # Extension
        telescope.enable = true; # Fuzzy finder
        nvim-tree.enable = true; # File explorer
        harpoon.enable = true; # Mark files to go back to

        # Language specific
        rustaceanvim.enable = true; # Tools for Rust
        nix.enable = true; # Tools for Nix

        # AI suggestions
        codeium-nvim = {
          enable = true;
          settings = {
            virtual_text = {
              enables = true;
            };
          };
        };
        # Debug
        dap.enable = true; # Debug server
    };
    
    # Plugins only available on nixpkgs
    extraPlugins = with pkgs.vimPlugins; [
    ];
    
    extraConfigVim = ''
    '';
  };
}
