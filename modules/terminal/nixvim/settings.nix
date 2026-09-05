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
              fg = lib.mkForce dashboardHeaderColor;
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

            -- Line number color per mode
            local mode_linenr_colors = {
              n = "#61AFEF", -- Normal
              i = "#98C379", -- Insert
              v = "#C678DD", -- Visual
              V = "#C678DD", -- Visual line
              ["\22"] = "#C678DD", -- Visual block (<C-v>)
              R = "#E06C75", -- Replace
              c = "#E5C07B", -- Command-line
              t = "#56B6C2", -- Terminal
            }
            local function set_mode_linenr_color()
              local color = mode_linenr_colors[vim.fn.mode()] or mode_linenr_colors.n
              vim.api.nvim_set_hl(0, "LineNr", { fg = color, bg = "none" })
              vim.api.nvim_set_hl(0, "CursorLineNr", { fg = color, bg = "none", bold = true })
            end
            vim.api.nvim_create_autocmd("ModeChanged", {
              pattern = "*:*",
              callback = set_mode_linenr_color,
            })
            vim.api.nvim_create_autocmd("ColorScheme", {
              callback = set_mode_linenr_color,
            })
            set_mode_linenr_color()

            -- Legible diff backgrounds.
            --
            -- base16-nvim hardcodes its diff backgrounds as an accent blended
            -- 80-90% of the way toward base00, with no config knob for it
            -- (lua/base16-colorscheme.lua:227-231). purpledream's base00 is
            -- #100510, so that blend leaves add/delete/text as near-identical
            -- dark smudges. Re-blend at a gentler ratio instead. Read from the
            -- live palette rather than hardcoded hexes so this keeps working if
            -- the stylix scheme changes.
            local DIFF_BLEND = 0.4

            local function set_diff_colors()
              local base16 = package.loaded["base16-colorscheme"]
              local c = base16 and base16.colors
              if not (c and c.base00) then
                return
              end

              local function rgb(h)
                return tonumber(h:sub(2, 3), 16), tonumber(h:sub(4, 5), 16), tonumber(h:sub(6, 7), 16)
              end
              local br, bg, bb = rgb(c.base00)
              local function blend(hex, pct)
                local r, g, b = rgb(hex)
                return string.format(
                  "#%02x%02x%02x",
                  math.floor(r + (br - r) * pct),
                  math.floor(g + (bg - g) * pct),
                  math.floor(b + (bb - b) * pct)
                )
              end

              vim.api.nvim_set_hl(0, "DiffAdd", { bg = blend(c.base0B, DIFF_BLEND) })
              vim.api.nvim_set_hl(0, "DiffDelete", { bg = blend(c.base08, DIFF_BLEND) })
              vim.api.nvim_set_hl(0, "DiffText", { bg = blend(c.base09, DIFF_BLEND) })
              -- Intra-line added region, brighter so it reads inside DiffAdd.
              vim.api.nvim_set_hl(0, "DiffTextAdd", { bg = blend(c.base0B, DIFF_BLEND - 0.15) })
              -- Changed lines stay neutral: base16 uses base01 here, and an
              -- accent this loud on every changed line drowns out DiffText.
              vim.api.nvim_set_hl(0, "DiffChange", { bg = c.base02 })
            end
            vim.api.nvim_create_autocmd("ColorScheme", {
              callback = set_diff_colors,
            })
            set_diff_colors()
          '';
        };
      };
    };
}
