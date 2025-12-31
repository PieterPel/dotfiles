{
  flake.modules.homeManager.nixvim-plugins =
    { config
    , lib
    , pkgs
    , ...
    }:
    {
      config = lib.mkIf config.modules.terminal.nixvim.enable {
        programs.nixvim.plugins = {
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
          gitblame.enable = true; # Show git blame
          diffview.enable = true; # Show git diff

          # Extension
          telescope.enable = true; # Fuzzy finder
          nvim-tree = {
            enable = true; # File explorer
            settings = {
              diagnostics = {
                enable = true;
                show_on_dirs = true;
              };
              git = {
                ignore = false;
              };
            };
          };
          harpoon.enable = true; # Mark files to go back to
          trouble.enable = true; # Give diagnostics overview
          lazygit.enable = true; # Lazygit from within nvim
          flash.enable = true; # Jump to anywhere
          claude-code.enable = true; # Claude-code support
          yazi = {
            # Yazi file explorer
            enable = true;
            settings = {
              open_for_directories = true;
            };
          };

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
          zig.enable = true;
          flutter-tools.enable = true;

          # Treesitter
          treesitter-context = {
            enable = true;
          };
          treesitter-textobjects.enable = true;
          treesitter = {
            autoLoad = true;
            enable = true;
            nixvimInjections = true;
            settings = {
              auto_install = false;
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
              basedpyright = {
                enable = false;
                # packageFallback = true; # Devshell basedpyright overrides global one # NOTE: may give issues if true?
                cmd = [
                  "basedpyright-langserver"
                  "--stdio"
                ];
              };
              ty.enable = true;
              ruff.enable = true;
              bashls.enable = true;
              yamlls.enable = true;
              taplo.enable = true;
              ts_ls.enable = true;
              eslint.enable = true;
              lua_ls.enable = true;
              gleam.enable = true;
              bicep.enable = false; # Requires manual stuff to get working https://nix-community.github.io/nixvim/plugins/lsp/servers/bicep/index.html
              terraformls.enable = true;
              rust_analyzer = {
                enable = true;
                installRustc = true;
                installCargo = true;
              };
              zls.enable = true;
              dartls.enable = true;
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
                #"copilot"
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
          avante = {
            enable = false;
            settings = {
              provider = "copilot";
              acp_providers = {
                gemini-cli = {
                  command = lib.getExe pkgs.gemini-cli;
                  # auth-method = null;
                };
              };
            };
          };

          copilot-chat.enable = false;
          windsurf-nvim = {
            enable = true;
            settings = {
              virtual_text = {
                enabled = true;
                keybindings = { };
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
              # pairs = { }; # I changed this for nvim-autopairs
            };
          };

          nvim-autopairs.enable = true;

          # Debug
          dap.enable = true; # Debug server

          # Testing
          neotest.enable = true;

          # Keeping track of time (enable with :WakaTimeApiKey)
          wakatime.enable = true;

          # Dependency of gemini-cli
          snacks.enable = true;
        };

        programs.nixvim.extraPlugins = with pkgs; [

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

          (vimUtils.buildVimPlugin {
            name = "gemini_cli";
            src = pkgs.fetchFromGitHub {
              owner = "marcinjahn";
              repo = "gemini-cli.nvim";
              # 18-07-2025
              rev = "c9fd62adda823628f5131a939d9c56ef7a898600";
              hash = "sha256-C4OI6NM+Bpa5WffmXY+tNLfuYyX0LNbmsAe9GDBRVCQ=";
            };
          })

          (vimUtils.buildVimPlugin {
            name = "opencode";
            src = pkgs.fetchFromGitHub {
              owner = "NIckvanDyke";
              repo = "opencode.nvim";
              # 02-09-2025
              rev = "a7142e20a96becf09ee1dd70a80396ca2ab7c66f";
              hash = "sha256-p02EXhbaawxX4xYC9fxXRD/klPxXpv1d2obUw5G8N3g=";
            };
          })

          pkgs.vimPlugins.transparent-nvim
        ];
      };
    };
}
