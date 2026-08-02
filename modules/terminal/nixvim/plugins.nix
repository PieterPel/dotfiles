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
          pkgs.jq
          pkgs.mdx-language-server
        ];
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
            octo = {
              enable = true; # GitHub issues/PRs (uses gh cli)
              settings.mappings = {
                # file_panel already navigates with plain j/k by default, no bracket issue there.
                # review_diff's changed-file/thread navigation defaults to bracket keys, which
                # are awkward on a split keyboard, so remap those specifically.
                review_diff = {
                  select_next_entry = {
                    lhs = "<leader>oj";
                    desc = "move to next changed file";
                  };
                  select_prev_entry = {
                    lhs = "<leader>ok";
                    desc = "move to previous changed file";
                  };
                  select_first_entry = {
                    lhs = "<leader>oJ";
                    desc = "move to first changed file";
                  };
                  select_last_entry = {
                    lhs = "<leader>oK";
                    desc = "move to last changed file";
                  };
                  next_thread = {
                    lhs = "<leader>on";
                    desc = "move to next thread";
                  };
                  prev_thread = {
                    lhs = "<leader>oN";
                    desc = "move to previous thread";
                  };
                };
              };
            };
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
              lazyLoad.enable = false;
              # No trigger/delay overrides: use which-key's own defaults so the
              # popup actually appears on <leader> etc. <leader><leader> manual
              # trigger is still set in binds.nix.
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
                pyrefly.enable = true;
                basedpyright = {
                  enable = false;
                  cmd = [
                    "basedpyright-langserver"
                    "--stdio"
                  ];
                  rootMarkers = [
                    "pyrightconfig.json"
                    "pyproject.toml"
                    ".git"
                  ];
                };
                ruff.enable = true;
                bashls.enable = true;
                yamlls.enable = true;
                taplo.enable = true;
                ts_ls.enable = true;
                eslint.enable = true;
                mdx_analyzer = {
                  enable = true;
                  package = null; # provided externally via home.packages
                  extraOptions.init_options.typescript.tsdk = "${pkgs.typescript}/lib/node_modules/typescript/lib";
                };
                lua_ls.enable = true;
                gleam.enable = false; # Issue with deno
                bicep.enable = false; # Requires manual stuff to get working https://nix-community.github.io/nixvim/plugins/lsp/servers/bicep/index.html
                terraformls.enable = true;
                rust_analyzer = {
                  enable = true;
                  installRustc = true;
                  installCargo = true;
                };
                zls.enable = true;
                dartls.enable = true;
                statix.enable = true;
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
              settings.ui.code_action = "";
              # Disable the code action lightbulb (flicker)
              settings.lightbulb = {
                enable = false;
                sign = false;
                virtual_text = false;
              };
            };

            conform-nvim = {
              enable = true;
              settings = {
                formatters_by_ft = {
                  python = [ "ruff_format" ];
                  javascript = [ "prettier" ];
                  typescript = [ "prettier" ];
                  typescriptreact = [ "prettier" ];
                  mdx = [ "prettier" ];
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
                dashboard = {
                  enabled = true; # Beautiful startup screen
                  # Avoid lazy.nvim startup stats to prevent `lazy.stats` module errors.
                  sections = [
                    {
                      text.__raw = ''
                        { {
                          "██████╗ ███████╗██████╗ ███████╗██╗      ██████╗ █████╗ ██╗\n"
                          .. "██╔══██╗██╔════╝██╔══██╗██╔════╝██║     ██╔════╝██╔══██╗██║\n"
                          .. "██████╔╝█████╗  ██████╔╝█████╗  ██║     ╚█████╗ ███████║██║\n"
                          .. "██╔══██╗██╔══╝  ██╔══██╗██╔══╝  ██║      ╚═══██╗██╔══██║██║\n"
                          .. "██║  ██║███████╗██████╔╝███████╗███████╗██████╔╝██║  ██║██║\n"
                          .. "╚═╝  ╚═╝╚══════╝╚═════╝ ╚══════╝╚══════╝╚═════╝ ╚═╝  ╚═╝╚═╝",
                          hl = "SnacksDashboardHeader"
                        } }
                      '';
                      align = "center";
                      padding = 1;
                    }
                    {
                      section = "keys";
                      gap = 1;
                      padding = 1;
                    }
                    { section = "recent_files"; }
                  ];
                };
                explorer = {
                  # Sidebar file viewer with git status; oil/yazi already own netrw
                  replace_netrw = false;
                };
                input.enabled = true; # Better rename/input dialogs
                notifier.enabled = true; # Better notifications
                quickfile.enabled = true;
                scroll.enabled = true; # Smooth scrolling
                statuscolumn.enabled = true; # Git signs in the left column
              };
            };
          };

          extraPlugins = with pkgs; [

            (vimUtils.buildVimPlugin {
              pname = "venv-selector";
              version = "2025-02-02";
              src = pkgs.fetchFromGitHub {
                owner = "pieterpel";
                repo = "venv-selector.nvim";
                # 02-02-2025
                rev = "268cbdf1feaa99f88e9e1cd636e40b4af986e100";
                hash = "sha256-UXKlVn4D6Qj4s01mcFRUsIgXh8c9KmAX5E16Z/RenYE=";
              };
            })

            pkgs.vimPlugins.transparent-nvim

            (vimUtils.buildVimPlugin {
              pname = "agentic-nvim";
              version = "2026-06-11";
              src = pkgs.fetchFromGitHub {
                owner = "carlos-algms";
                repo = "agentic.nvim";
                rev = "a19fee663aa8be5f46f0af6fc0b46427b0e75cf2";
                hash = "sha256-ZT1ME4E8jwC6DPLVpEgCudL8go91q7PkfJn5ylajmYA=";
              };
            })

            (vimUtils.buildVimPlugin {
              pname = "claudecode-nvim";
              version = "2026-07-05";
              src = pkgs.fetchFromGitHub {
                owner = "coder";
                repo = "claudecode.nvim";
                rev = "2390c6e45c4789072c293ac69de051d169668b29";
                hash = "sha256-oMBPSRQFDmJ9Lq+ZP8vFMHaocm4sPX3D/orVMNwVXuM=";
              };
            })

            (vimUtils.buildVimPlugin {
              pname = "atlas-nvim";
              version = "2026-08-02";
              src = pkgs.fetchFromGitHub {
                owner = "emrearmagan";
                repo = "atlas.nvim";
                rev = "d67faec8c6da7743d60f9afdc87722f44a3eb010";
                hash = "sha256-A6jH53sa753FCDoc+GkdU98rU3ROquznvpxVTNw/sK4=";
              };
            })

            (vimUtils.buildVimPlugin {
              pname = "satellite-nvim";
              version = "2026-08-02";
              src = pkgs.fetchFromGitHub {
                owner = "lewis6991";
                repo = "satellite.nvim";
                rev = "87843c9c8f28b54332497302de380a6d94c9e82b";
                hash = "sha256-2kvs9HgNcLy7ym2C2XZRv3Qa2ttNLdpa9l7oRYy8KLQ=";
              };
            })
          ];

          autoCmd = [
            {
              event = "FileType";
              pattern = [
                "AgenticChat"
                "AgenticInput"
              ];
              callback.__raw = ''
                function()
                  local ss = require('smart-splits')
                  vim.keymap.set({ "n", "i" }, "<C-h>", ss.move_cursor_left,  { buffer = true, silent = true })
                  vim.keymap.set({ "n", "i" }, "<C-j>", ss.move_cursor_down,  { buffer = true, silent = true })
                  vim.keymap.set({ "n", "i" }, "<C-k>", ss.move_cursor_up,    { buffer = true, silent = true })
                  vim.keymap.set({ "n", "i" }, "<C-l>", ss.move_cursor_right, { buffer = true, silent = true })
                end
              '';
            }
            {
              event = "FileType";
              pattern = [ "oil" ];
              callback.__raw = ''
                function()
                  vim.keymap.set("n", "<leader>cs", "<cmd>ClaudeCodeTreeAdd<CR>", { buffer = true, silent = true, desc = "Claude Code: add file" })
                end
              '';
            }
          ];

          extraConfigLua = ''
            vim.filetype.add({ extension = { mdx = "mdx" } })
            -- nixpkgs' nvim-treesitter ships no mdx grammar; reuse markdown's for highlighting
            vim.treesitter.language.register("markdown", "mdx")

            require("claudecode").setup({
              -- harnt.nvim now owns Claude's IDE-integration lockfile; if this
              -- also auto-starts, both register competing "Neovim" IDE entries
              -- for the same workspace and the CLI's /ide picker can't tell
              -- them apart (confirmed: it silently connects to whichever
              -- registered first, i.e. this one, ignoring harnt entirely).
              auto_start = false,
              focus_after_send = true,
              git_repo_cwd = true,
              terminal = {
                provider = "snacks",
                auto_insert = false,
                snacks_win_opts = {
                  position = "right",
                  width = 0.40,
                  border = "rounded",
                  keys = {
                    claude_hide = { "<C-,>", function(self) self:hide() end, mode = "t", desc = "Hide" },
                  },
                },
              },
              diff_opts = {
                layout = "unified",
                keep_terminal_focus = true,
              },
            })

            -- DEV MODE: harnt.nvim isn't packaged via Nix yet, so edits to the
            -- local checkout show up after just restarting nvim (no
            -- home-manager switch needed). Once it stabilizes, replace this
            -- with a pinned vimUtils.buildVimPlugin + fetchFromGitHub entry
            -- in extraPlugins, like venv-selector/claudecode above.
            local harnt_dev_path = os.getenv("HOME") .. "/home/private-projects/harnt.nvim"
            if vim.fn.isdirectory(harnt_dev_path) == 1 then
              vim.opt.rtp:prepend(harnt_dev_path)
              require("harnt").setup({})
            end

            require("atlas").setup({
              pulls = {
                providers = {
                  github = {
                    -- uses `gh` cli auth, same as Octo. Default view (no
                    -- `views` set) is a single catch-all "involves:@me" tab,
                    -- so define these explicitly to get a real assignee view.
                    views = {
                      { name = "Assigned", key = "1", search = "is:pr assignee:@me archived:false" },
                      { name = "Authored", key = "2", search = "is:pr author:@me archived:false" },
                      { name = "Reviewing", key = "3", search = "is:pr review-requested:@me archived:false" },
                    },
                  },
                },
              },
              issues = {
                providers = {
                  github = { },
                },
              },
              keymaps = {
                pulls = {
                  review = {
                    -- Same rationale as Octo's remap above: bracket-key nav is
                    -- awkward on a split keyboard.
                    next_file = "<leader>Aj",
                    previous_file = "<leader>Ak",
                    next_comment = "<leader>An",
                    previous_comment = "<leader>AN",
                  },
                },
              },
            })

            require("satellite").setup({})

            require("agentic").setup({
              provider = "claude-agent-acp",
              acp_providers = {
                ["claude-agent-acp"] = {
                  env = { MAX_THINKING_TOKENS = "10000" },
                },
              },
              windows = {
                position = "right",
                width = "35%",
              },
              diff_preview = {
                enabled = true,
                layout = "inline",
                center_on_navigate_hunks = true,
              },
              folding = {
                tool_calls = {
                  enabled = true,
                  threshold = 10,
                },
              },
            })
          '';
        }; # end programs.nixvim
      };
    };
}
