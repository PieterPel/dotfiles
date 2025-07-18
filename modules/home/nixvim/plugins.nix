{
  pkgs,
  ...
}:

{
  programs.nixvim = {
    plugins = {
      # General
      undotree.enable = true; # Virtualize undo history
      comment.enable = true; # Better commenting
      direnv.enable = true; # Direnv integration
      lz-n.enable = true; # Lazy loading

      # Apearance
      lightline.enable = true; # Pretty bar at the bottom
      web-devicons.enable = true; # Icons
      colorizer.enable = true; # Inline colors
      twilight.enable = true; # Dim inactive code
      todo-comments.enable = true; # See notes/todos better

      # Extension
      telescope.enable = true; # Fuzzy finder
      nvim-tree.enable = true; # File explorer
      harpoon.enable = true; # Mark files to go back to
      trouble.enable = true; # Give diagnostics overview
      lazygit.enable = true; # Lazygit from within nvim

      # Language specific
      /*
        rustaceanvim = {
               enable = true;
               settings = {
                 tools.enable_clippy = true;
                 server.default_settings = {
                   rust_analyzer = {
                     check.command = "clippy";
                   };
                 };
               };
             };
      */

      nix.enable = true; # Tools for Nix
      typescript-tools.enable = true; # Tools for TypeScript
      render-markdown = {
        # Render markdown
        enable = true;
        lazyLoad.settings.ft = "markdown";
      };

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
          ts_ls.enable = true;
          lua_ls.enable = true;
          rust_analyzer = {
            enable = true;
            installRustc = true;
            installCargo = true;
          };
        };
      };

      lsp-format.enable = true;

      # Completion
      cmp.enable = true; # Needed for Windsurf
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
      copilot-chat.enable = true;
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
          files = { };
          comment = { };
          bracketed = { };
          indentscope = { };
          tabline = { };
          pairs = { };
        };
      };

      # Debug
      dap.enable = true; # Debug server

      # Testing
      neotest.enable = true;

      # Keeping track of time (enable with :WakaTimeApiKey)
      wakatime.enable = true;
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
  };
}
