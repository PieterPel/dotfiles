{config, pkgs, ...}:
{
  home.packages = with pkgs; [
    fd
    rust-analyzer
  ];

  home.sessionVariables = {
    RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
  };

  programs.nixvim = {
    nixpkgs.config.allowUnfree = true; # nixvim uses its own nixpkgs!!

    enable = true;

    #colorscheme = "oxocarbon";
    #colorschemes.oxocarbon.enable = true;

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
      { key = "<up>"; action = "<nop>"; mode = ["n" "i" "v"]; }
      { key = "<down>"; action = "<nop>"; mode = ["n" "i" "v"]; }
      { key = "<left>"; action = "<nop>"; mode = ["n" "i" "v"]; }
      { key = "<right>"; action = "<nop>"; mode = ["n" "i" "v"]; }
      
      # Telescope
      { key = "<leader>ff"; action = "<cmd>Telescope find_files<CR>"; }
      { key = "<leader>fg"; action = "<cmd>Telescope live_grep<CR>"; }
      { key = "<leader>fb"; action = "<cmd>Telescope buffers<CR>"; }
      { key = "<leader>fh"; action = "<cmd>Telescope help_tags<CR>"; }

      # Nvimtree
      { key = "<leader>e"; action = "<cmd>NvimTreeToggle<CR>"; }

      # venv-select
      {key = "<leader>V"; action = "<cmd>VenvSelect<CR>"; }

      # Splits and tabs
      { key = "<leader>h"; action = "<cmd>split<CR>"; }
      { key = "<leader>v"; action = "<cmd>vsplit<CR>"; }
      { key = "<leader>t"; action = "<cmd>tabnew<CR>"; }

      # Utility
      { key = "<leader>q"; action = "<cmd>quit<CR>";}
      { key = "<C-e"; action = "<cmd>lua vim.diagnostic.open_float()<CR>"; }
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
/*         rustaceanvim = {
          enable = true;
          settings = {
            tools.enable_clippy = true;
            server.default_settings = {
              rust_analyzer = {
                check.command = "clippy";
              };
            };
          };
        }; */

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
              enable = false;
            };
            fold = {
              enable = true;
            };
          };
        };

        # LSP
        lsp = {
          enable = true;
          inlayHints = true;
          servers = {
            nil_ls.enable = true;
            dockerls.enable = true;
            pyright.enable = true;
            ruff.enable = true;
            bashls.enable = true;
            yamlls.enable = true;
            taplo.enable = true;
            rust_analyzer = {
              enable = true;
              installRustc = true;
              installCargo = true;
            };
          };
        };

        lsp-format.enable = true;

        # Completion
        cmp.enable = true; # Needed for Windurf
        blink-copilot.enable = true;
        blink-cmp = {
          enable = true;
          settings = {
            keymap = {
              "<C-k>" = [
                "select_prev"
                "fallback"
              ];
              "<C-j>" = [
                "select_next"
                "fallback"
              ];
            };
          };
          settings.sources = {
            default = [
              "lsp"
              "path"
              "buffer"
              "copilot"
            ];
  
            providers = {
              copilot = {
                async = true;
                module = "blink-copilot";
                name = "copilot";
                score_offset = 100;
                # Optional configurations
                opts = {
                  max_completions = 3;
                  max_attempts = 4;
                  kind = "Copilot";
                  debounce = 750;
                  auto_refresh = {
                    backward = true;
                    forward = true;
                  };
                };
              };
            };
          };
        };

        # AI suggestions
        windsurf-nvim = {
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
    
    extraPlugins = with pkgs; [

      (vimUtils.buildVimPlugin {
        name = "venv-selector";
        src = pkgs.fetchFromGitHub {
            owner = "pieterpel";
            repo = "venv-selector.nvim";
            # 02-02-2025
            rev = "268cbdf1feaa99f88e9e1cd636e40b4af986e100";
            hash = "sha256-UXKlVn4D6Qj4s01mcFRUsIgXh8c9KmAX5E16Z/RenYE=";
        };
      })
      
      pkgs.vimPlugins.transparent-nvim
    ];
    
    extraConfigVim = ''
    '';

    extraConfigLua = ''
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.server_capabilities.inlayHintProvider then
            vim.lsp.inlay_hint.enable(true, { args.buf }) 
          end
        end,
      })

      require("venv-selector").setup({
        settings = { 
          search = {
            find_devenvs = {
              command = "fd '.devenv/state/venv/bin/python3$' ~/Programming/Python --full-path -IHL -E /proc"
            }
          }
        }  
      })
    '';
  };
}
