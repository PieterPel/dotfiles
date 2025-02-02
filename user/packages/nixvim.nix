{config, pkgs, ...}:
{
  programs.nixvim = {
    nixpkgs.config.allowUnfree = true; # nixvim uses its own nixpkgs!!

    enable = true;

    colorscheme = "oxocarbon";
    colorschemes.oxocarbon.enable = true;

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

    globals = {
     mapleader = " ";
     maplocalleader = " ";
    };

    keymaps = [
      # Disable arrow keys

      
      # Telescope
      { key = "<leader>ff"; action = "<cmd>Telescope find_files<CR>"; }
      { key = "<leader>fg"; action = "<cmd>Telescope live_grep<CR>"; }
      { key = "<leader>fb"; action = "<cmd>Telescope buffers<CR>"; }
      { key = "<leader>fh"; action = "<cmd>Telescope help_tags<CR>"; }
    ];

    clipboard = {
      # Use system clipboard
      register = "unnamedplus";
      providers.wl-copy.enable = true;
    };
    
    plugins = {
        # General
        undotree.enable = true; # Virtualize undo history
        comment.enable = true; # Better commenting

        # Apearance
        lightline.enable = true; # Pretty bar at the bottom
        web-devicons.enable = true; # Icons

        # Extension
        telescope.enable = true; # Fuzzy finder
        nvim-tree.enable = true; # File explorer
        harpoon.enable = true; # Mark files to go back to

        # Language specific
        rustaceanvim = {
          enable = true;
          settings = {
            tools.enable_clippy = true;
          };
        };

        nix.enable = true; # Tools for Nix

        # Treesitter
        treesitter-context.enable = true;
        treesitter-textobjects.enable = true;
        treesitter = {
          enable = true;
          nixvimInjections = true;
          settings = {
            auto_install = true;
            highlight = {
              enable = true;
            };
            indent = {
              enable = true;
            };
            fold = {
              enable = true;
            };
          };
        };

        # LSP
        lsp = {
          enable = true;
          servers = {
            nil_ls.enable = true;
            dockerls.enable = true;
            pyright.enable = true;
            bashls.enable = true;
            yamlls.enable = true;
            taplo.enable = true;
          };
        };

        # Completion
        cmp.enable = true; # Needed for Codeium
        blink-cmp = {
          enable = true;
        };

        # AI suggestions
        codeium-nvim = {
          enable = true;
          settings = {
            virtual_text = {
              enabled = true;
              keybindings = {
              };
            };
          };
        };

        # Bunch of small utilities
        mini = {
          enable = true;
          modules = {
            files = {};
            comment = {};
            bracketed = {};
            indentscope = {};
            tabline = {};
            pairs = {};
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
