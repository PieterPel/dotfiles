{
  config,
  pkgs,
  ...
}:

let
  isWayland = builtins.hasAttr "WAYLAND_DISPLAY" config.home.sessionVariables;
  autoAutoreadSrc = pkgs.fetchFromGitHub {
    owner = "TheZoq2";
    repo = "neovim-auto-autoread";
    rev = "21fc7d47eaaec03f4e5ab76abacc00d8702e4590";
    sha256 = "sha256-MwfxxcLazHM5AWNZuujP+5f1iJgxrFyw7aiwW1T733M=";
  };

  autoAutoreadRplugin =
    pkgs.runCommand "auto-autoread-rplugin"
      {
      }
      ''
        mkdir -p $out
        cp -r ${autoAutoreadSrc}/rplugin $out/
      '';
in
{
  home.packages = with pkgs; [
    fd
    rust-analyzer
    (python313.withPackages (ps: with ps; [ pynvim ]))
  ];

  home.sessionVariables = {
    RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
  };

  home.file.".config/nvim/rplugin".source = "${autoAutoreadRplugin}/rplugin";

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
      let g:python3_host_prog = exepath('python3')
      set autoread
      if has('nvim') "Prevent errors when using standard vim
          autocmd VimEnter * AutoreadLoop
      endif

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

      vim.opt.rtp:append("${autoAutoreadRplugin}")
      require("gemini_cli").setup()
    '';
  };
}
