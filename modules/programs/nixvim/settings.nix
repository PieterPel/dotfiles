{ lib
, config
, pkgs
, ...
}:

let
  isWayland = builtins.hasAttr "WAYLAND_DISPLAY" config.home.sessionVariables;
  cfg = config.modules.programs.nixvim;
in
{
  options.modules.programs.nixvim = {
    enable = lib.mkEnableOption "Enable Nixvim configuration.";
  };

  config = lib.mkIf cfg.enable {

    packages = with pkgs; [
      fd
      rust-analyzer
      the_silver_searcher  # ag - The Silver Searcher for fast text searching
      ripgrep  # rg - Alternative fast searcher as fallback
    ];

    envVars = {
      RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
    };

    programs.nixvim = {
      nixpkgs.config.allowUnfree = true; # nixvim uses its own nixpkgs!!

      enable = true;

      diagnostic.settings = {
        # Enable virtual text for inline diagnostics
        virtual_text = {
          spacing = 2;
          prefix = "";
        };

        # Configure signs in the sign column
        signs = {
          text = {
            ERROR = "E";
            WARN = "W";
            INFO = "I";
            HINT = "H";
          };
        };

        # Underline problematic text
        underline = true;

        # Update diagnostics in insert mode
        update_in_insert = false;

        # Sort diagnostics by severity
        severity_sort = true;

        # Floating window configuration
        float = {
          border = "rounded";
          source = "always";
          header = "";
          prefix = "";
        };
      };

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

        # Folding configuration
        foldenable = true;
        foldmethod = "expr";
        foldexpr = "nvim_treesitter#foldexpr()";
        foldlevel = 99;  # Start with all folds open
        foldlevelstart = 99;  # Start with all folds open

      };

      globals = {
        mapleader = " ";
        maplocalleader = " ";
      };

      clipboard = {
        # Use system clipboard
        register = "unnamedplus";
        providers.wl-copy.enable = isWayland;
      };

      extraConfigVim = ''
        " Make lightline the only bar and change the theme
        set noshowmode
        set laststatus=2
        let g:lightline = {
          \ 'colorscheme': 'rosepine',
          \ }

        " Autoreload files when changed externally
        set autoread

        " Fix slow exiting of terminal mode
        set ttimeoutlen=10
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

        require("gemini_cli").setup()

        -- Configure folding to exclude function arguments
        vim.api.nvim_create_autocmd("FileType", {
          pattern = "*",
          callback = function()
            -- Set custom fold text to show function signatures without folding arguments
            vim.opt_local.foldtext = [[substitute(getline(v:foldstart),'\\t',repeat('\ ',&tabstop),'g').'...'.trim(getline(v:foldend))]]
          end,
        })

        -- Custom folding function to avoid folding function arguments
        vim.api.nvim_create_autocmd("FileType", {
          pattern = {"python", "javascript", "typescript", "rust", "lua", "nix"},
          callback = function()
            vim.wo.foldmethod = "expr"
            vim.wo.foldexpr = "nvim_treesitter#foldexpr()"
            -- Prevent folding of function arguments by setting minimum fold level
            vim.wo.foldminlines = 3  -- Only fold blocks with 3+ lines
          end,
        })

        -- Configure Telescope to use Silver Searcher for specific searches
        local telescope = require('telescope')
        local actions = require('telescope.actions')
        
        -- Custom live_grep function using ag (silver searcher)
        local function live_grep_ag()
          require('telescope.builtin').live_grep({
            vimgrep_arguments = {
              'ag',
              '--nocolor',
              '--noheading',
              '--filename',
              '--numbers',
              '--column',
              '--smart-case',
              '--hidden'
            }
          })
        end

        -- Make the custom function available globally
        vim.api.nvim_create_user_command('TelescopeLiveGrepAg', live_grep_ag, {})
      '';
    };
  };
}
