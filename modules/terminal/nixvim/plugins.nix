{
  flake.modules.homeManager.nixvim-plugins =
    { config
    , lib
    , pkgs
    , ...
    }:
    {
      config = lib.mkIf config.modules.terminal.nixvim.enable {
        home.packages = [
          pkgs.ruff
          pkgs.prettierd
          pkgs.nixfmt
          pkgs.fzf
        ];
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
          noice.enable = true; # Better notifications
          fidget.enable = true; # Show lsp progress
          illuminate = {
            enable = true;
            settings = {
              delay = 100;
              underCursor = false; # Don't highlight the one you are on
            };
          };

          # File diffs
          diffview = {
            enable = true;
            settings = {
              view.default.layout = "diff2_horizontal"; # Or "diff2_vertical" if you have a wide screen
              file_panel.listing_style = "tree"; # Looks like a proper file explorer
            };
          };

          # Git
          gitsigns = {
            enable = true;
            settings = {
              current_line_blame = false;
              current_line_blame_opts = {
                virt_text = true;
                virt_text_pos = "eol";
                delay = 500;
              };
              signs = {
                add = {
                  text = "│";
                };
                change = {
                  text = "│";
                };
                delete = {
                  text = "_";
                };
                topdelete = {
                  text = "‾";
                };
                changedelete = {
                  text = "~";
                };
              };
            };
          };

          # Extension
          telescope = {
            enable = true;
            settings = { };
            extensions = {
              ui-select = {
                enable = true;
                settings = {
                  # This makes the menu a small dropdown under your cursor
                  specific_opts.codeactions = true;
                };
              };
              fzf-native = {
                enable = true;
              };
            };
          };
          nvim-tree = {
            enable = false; # File explorer
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
          flash = {
            enable = true; # Jump to anywhere
            settings = {
              highlight = {
                backdrop = true;
              };
            };
            smart-splits.enable = true; # Seamless navigation between nvim and tmux
            yazi = {
              # Yazi file explorer
              enable = true;
              settings = {
                open_for_directories = true;
              };
            };

            aerial = {
              enable = true;
              settings = {
                # Use these backends in order
                backends = [
                  "treesitter"
                  "lsp"
                  "markdown"
                  "man"
                ];

                # Layout settings to make it feel like a sidebar
                layout = {
                  min_width = 30;
                  default_direction = "left";
                  placement = "window";
                };

                attach_mode = "global";

                icons = {
                  # You can customize icons here or use defaults
                };

                highlight_on_hover = true;
                manage_folds = true;

                filter_kind = [
                  "Class"
                  "Constructor"
                  "Constant"
                  "Enum"
                  "Function"
                  "Interface"
                  "Method"
                  "Module"
                  "Struct"
                ];
              };
            };

            oil = {
              enable = true;
              settings = {
                default_file_explorer = true; # Replaces netrw
                delete_to_trash = true;
                skip_confirm_for_simple_edits = true;
                view_options = {
                  show_hidden = true; # Show dotfiles
                };
              };
            };

            which-key = {
              enable = true;
              lazyload.enable = false;
              settings = {
                # This effectively disables the "auto" popup behavior
                # formatting it like this ensures it overrides default "auto"
                triggers = [ ];
                delay = 10000; # leader leader is set in binds.nix
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
            treesitter-textobjects = {
              enable = true;

              settings = {
                select = {
                  enable = true;
                  lookahead = true;

                  keymaps = {
                    "aa" = "@parameter.outer";
                    "ia" = "@parameter.inner";
                    "af" = "@function.outer";
                    "if" = "@function.inner";
                    "ac" = "@class.outer";
                    "ic" = "@class.inner";
                  };
                };

                move = {
                  enable = true;
                  goto_next_start = {
                    "]m" = "@function.outer";
                    "]c" = "@class.outer";
                  };
                  goto_previous_start = {
                    "[m" = "@function.outer";
                    "[c" = "@class.outer";
                  };
                };
              };
            };
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
                ty.enable = false; # Not production ready at all in jan '26
                basedpyright = {
                  # Keep as fallback for ty
                  enable = true;
                  cmd = [
                    "basedpyright-langserver"
                    "--stdio"
                  ];
                  settings = {
                    disableOrganizeImports = true;
                    analysis = {
                      # Let ty do all type checking
                      typeCheckingMode = "off";
                    };
                  };
                };
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
              keymaps = {
                silent = true; # Makes the binds silent (no command echo)

                lspBuf = {
                  "gD" = "references";
                  "gt" = "type_definition";
                  "gi" = "implementation";
                  "ca" = "code_action";
                };

                # 2. Diagnostic Bindings (vim.diagnostic.*)
                diagnostic = {
                  "<leader>k" = "goto_prev";
                  "<leader>j" = "goto_next";
                };
              };
            };

            inc-rename.enable = true; # Live renaming

            lspsaga = {
              enable = true;
              ui.code_action = "";
            };

            conform-nvim = {
              enable = true;
              settings = {
                formatters_by_ft = {
                  python = [ "ruff_format" ];
                  javascript = [ "prettier" ];
                  typescript = [ "prettier" ];
                  typescriptreact = [ "prettier" ];
                  nix = [ "nixfmt" ];
                  # For everything else, this list is empty, so it hits the fallback
                  "_" = [ "trim_whitespace" ];
                };

                format_on_save = {
                  timeout_ms = 500;
                  # Format by lsp as fallback
                  lsp_fallback = true;
                };
              };
            };

            # Completion
            cmp.enable = true; # Needed for Windsurf
            blink-copilot.enable = false;
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
                  git = {
                    module = "blink-cmp-git";
                    name = "git";
                    score_offset = 100;
                    opts = {
                      commit = { };
                      git_centers = {
                        git_hub = { };
                      };
                    };
                  };
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
                comment = { };
                bracketed = { };
                indentscope = { };
                tabline = { };
                ai = {
                  n_lines = 500; # How many lines nearby to search
                };
              };
            };

            nvim-autopairs.enable = true;

            # Debug
            dap.enable = true; # Debug server

            # Testing
            neotest.enable = true;

            # Keeping track of time (enable with :WakaTimeApiKey)
            wakatime.enable = true;

            # UI improvements
            snacks = {
              enable = true;
              settings = {
                bigfile.enabled = true;
                dashboard.enabled = true; # Beautiful startup screen
                input.enabled = true; # Better rename/input dialogs
                notifier.enabled = true; # Better notifications
                quickfile.enabled = true;
                scroll.enabled = true; # Smooth scrolling
                statuscolumn.enabled = true; # Git signs in the left column
              };
            };
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

            pkgs.vimPlugins.transparent-nvim
          ];
        };
      };
    }
