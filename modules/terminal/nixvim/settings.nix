{
  flake.modules.homeManager.nixvim-settings =
    { lib
    , config
    , pkgs
    , ...
    }:
    let
      isWayland = builtins.hasAttr "WAYLAND_DISPLAY" config.home.sessionVariables;
      cfg = config.modules.terminal.nixvim;
      dashboardHeaderColor = "#6A18D1";
    in
    {
      options.modules.programs.nixvim = {
        enable = lib.mkEnableOption "Enable Nixvim configuration.";
      };

      config = lib.mkIf cfg.enable {

        # TODO: having rust analyzer setup like this is not ideal, should be per dev flake
        packages = with pkgs; [
          fd
          rust-analyzer
        ];

        home.sessionVariables = {
          RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
        };

        programs.nixvim = {
          enable = true;
          nixpkgs.config.allowUnfree = true; # nixvim uses its own nixpkgs!!

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

            swapfile = true;
            # The "//" forces nvim to save the file as "%path%to%file.swp"
            # to prevent name collisions in the temp folder.
            directory = "/tmp//,.";

            scrolloff = 8;
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

          # Define custom highlight groups here
          highlight = {
            SnacksDashboardHeader = {
              fg = dashboardHeaderColor;
            };
          };

          extraConfigVim = ''
            " Make lightline the only bar and change the theme
            set noshowmode
            set laststatus=2
            let g:lightline = {
              \ 'colorscheme': 'rosepine',
              \ }

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
                }
              }  
            })

            -- https://stackoverflow.com/questions/62100785/auto-reload-file-and-in-neovim-and-auto-reload-nerbtree
            vim.o.autoread = true
            vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI", "FocusGained" }, {
              command = "if mode() != 'c' | checktime | endif",
              pattern = { "*" },
            })

            -- More details: https://github.com/mikavilpas/yazi.nvim/issues/802
            vim.g.loaded_netrwPlugin = 1

            -- Let terminal transparency show through
            local function set_transparent_bg()
              vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
              vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
              vim.api.nvim_set_hl(0, "LineNr", { bg = "none" })
              vim.api.nvim_set_hl(0, "CursorLineNr", { bg = "none" })
              vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
              vim.api.nvim_set_hl(0, "FoldColumn", { bg = "none" })
            end
            vim.api.nvim_create_autocmd("ColorScheme", {
              callback = function()
                set_transparent_bg()
                vim.api.nvim_set_hl(0, "SnacksDashboardHeader", { fg = "${dashboardHeaderColor}" })
              end,
            })
            set_transparent_bg()
          '';
        };
      };
    };
}
