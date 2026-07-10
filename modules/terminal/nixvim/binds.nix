{
  flake.modules.homeManager.nixvim-binds =
    { config, lib, ... }:
    {
      config = lib.mkIf config.modules.terminal.nixvim.enable {
        programs.nixvim.keymaps = [
          # Disable arrow keys
          {
            key = "<up>";
            action = "<nop>";
            mode = [
              "n"
              "i"
              "v"
            ];
          }
          {
            key = "<down>";
            action = "<nop>";
            mode = [
              "n"
              "i"
              "v"
            ];
          }
          {
            key = "<left>";
            action = "<nop>";
            mode = [
              "n"
              "i"
              "v"
            ];
          }
          {
            key = "<right>";
            action = "<nop>";
            mode = [
              "n"
              "i"
              "v"
            ];
          }

          # Smart-splits navigation
          {
            key = "<C-h>";
            action.__raw = "require('smart-splits').move_cursor_left";
            mode = [ "n" "t" ];
            options.desc = "Move to left split";
          }
          {
            key = "<C-j>";
            action.__raw = "require('smart-splits').move_cursor_down";
            mode = [ "n" "t" ];
            options.desc = "Move to split below";
          }
          {
            key = "<C-k>";
            action.__raw = "require('smart-splits').move_cursor_up";
            mode = [ "n" "t" ];
            options.desc = "Move to split above";
          }
          {
            key = "<C-l>";
            action.__raw = "require('smart-splits').move_cursor_right";
            mode = [ "n" "t" ];
            options.desc = "Move to right split";
          }

          # Telescope
          {
            key = "<leader>ff";
            action = "<cmd>Telescope find_files<CR>";
          }
          {
            key = "<leader>fg";
            action = "<cmd>Telescope live_grep<CR>";
          }
          {
            key = "<leader>fb";
            action = "<cmd>Telescope buffers<CR>";
          }
          {
            key = "<leader>fh";
            action = "<cmd>Telescope help_tags<CR>";
          }

          # Harpoon
          {
            key = "<leader>a";
            action.__raw = "function() require('harpoon'):list():add() end";
            options.desc = "Add file to harpoon";
          }
          {
            key = "<leader>m";
            action.__raw = "function() local harpoon = require('harpoon'); harpoon.ui:toggle_quick_menu(harpoon:list()) end";
            options.desc = "Toggle harpoon menu";
          }
          {
            key = "<leader>1";
            action.__raw = "function() require('harpoon'):list():select(1) end";
            options.desc = "Navigate to harpoon file 1";
          }
          {
            key = "<leader>2";
            action.__raw = "function() require('harpoon'):list():select(2) end";
            options.desc = "Navigate to harpoon file 2";
          }
          {
            key = "<leader>3";
            action.__raw = "function() require('harpoon'):list():select(3) end";
            options.desc = "Navigate to harpoon file 3";
          }
          {
            key = "<leader>4";
            action.__raw = "function() require('harpoon'):list():select(4) end";
            options.desc = "Navigate to harpoon file 4";
          }
          {
            key = "<C-n>";
            action.__raw = "function() require('harpoon'):list():next() end";
            options.desc = "Navigate to next harpoon file";
          }
          {
            key = "<C-p>";
            action.__raw = "function() require('harpoon'):list():prev() end";
            options.desc = "Navigate to previous harpoon file";
          }

          # Buffer navigation
          {
            key = "<leader>n";
            action = "<cmd>bnext<CR>";
            options.desc = "Next buffer";
          }
          {
            key = "<leader>p";
            action = "<cmd>bprevious<CR>";
            options.desc = "Previous buffer";
          }
          {
            key = "<leader>d";
            action = "<cmd>bdelete<CR>";
            options.desc = "Delete buffer";
          }

          # Nvimtree
          {
            key = "<leader>e";
            action = "<cmd>NvimTreeToggle<CR>";
          }

          # venv-select
          {
            key = "<leader>V";
            action = "<cmd>VenvSelect<CR>";
          }

          # Trouble
          {
            key = "<leader>xx";
            action = "<cmd>Trouble diagnostics toggle<CR>";
          }
          {
            key = "<leader>xX";
            action = "<cmd>Trouble diagnostics toggle.buf=0<CR>";
          }

          # Debug

          # Splits and tabs
          {
            key = "<leader>h";
            action = "<cmd>split<CR>";
          }
          {
            key = "<leader>v";
            action = "<cmd>vsplit<CR>";
          }
          {
            key = "<leader>t";
            action = "<cmd>tabnew<CR>";
          }

          # agentic.nvim
          {
            key = "<C-;>";
            action.__raw = "function() require('agentic').toggle() end";
            mode = [ "n" "v" "i" ];
            options.desc = "Toggle Agentic chat";
          }
          {
            key = "<C-'>";
            action.__raw = "function() require('agentic').add_selection_or_file_to_context() end";
            mode = [ "n" "v" ];
            options.desc = "Add file/selection to Agentic context";
          }
          {
            key = "<leader>cg";
            action.__raw = "function() require('agentic').new_session() end";
            mode = [ "n" "v" "i" ];
            options.desc = "Agentic: new session";
          }

          # claudecode.nvim
          {
            key = "<leader>cc";
            action = "<cmd>ClaudeCode<CR>";
            options.desc = "Claude Code: toggle";
          }
          {
            key = "<leader>cf";
            action = "<cmd>ClaudeCodeFocus<CR>";
            options.desc = "Claude Code: focus";
          }
          {
            key = "<leader>cm";
            action = "<cmd>ClaudeCodeSelectModel<CR>";
            options.desc = "Claude Code: select model";
          }
          {
            key = "<leader>cb";
            action = "<cmd>ClaudeCodeAdd %<CR>";
            options.desc = "Claude Code: add current buffer";
          }
          {
            key = "<leader>cs";
            action = "<cmd>ClaudeCodeSend<CR>";
            mode = [ "v" ];
            options.desc = "Claude Code: send selection";
          }
          {
            key = "<leader>ca";
            action = "<cmd>ClaudeCodeDiffAccept<CR>";
            options.desc = "Claude Code: accept diff";
          }
          {
            key = "<leader>cx";
            action = "<cmd>ClaudeCodeDiffDeny<CR>";
            options.desc = "Claude Code: deny diff";
          }
          {
            key = "<leader>cX";
            action = "<cmd>ClaudeCodeCloseAllDiffs<CR>";
            options.desc = "Claude Code: close all diffs";
          }
          {
            key = "<leader>cz";
            action.__raw = ''
              function()
                local bufnr = require("claudecode.terminal").get_active_bufnr()
                if not bufnr then return end
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                  if vim.api.nvim_win_get_buf(win) == bufnr then
                    local current = vim.api.nvim_win_get_width(win)
                    local total = vim.o.columns
                    if current > total * 0.6 then
                      vim.api.nvim_win_set_width(win, math.floor(total * 0.40))
                    else
                      vim.api.nvim_win_set_width(win, total)
                    end
                    break
                  end
                end
              end
            '';
            options.desc = "Claude Code: zoom toggle";
          }
          {
            key = "<C-,>";
            action = "<cmd>ClaudeCodeFocus<CR>";
            mode = [
              "n"
              "v"
            ];
            options.desc = "Claude Code: focus (float toggle)";
          }
          {
            key = "<leader>cd";
            action.__raw = ''
              function()
                local diff = vim.fn.system("git diff HEAD")
                require("claudecode.terminal").send_to_terminal("Review this diff:\n" .. diff, { submit = false })
              end
            '';
            options.desc = "Claude Code: send git diff";
          }

          {
            key = "<leader>lg";
            action = "<cmd>LazyGit<CR>";
          }

          # Render markdown
          {
            key = "<leader>md";
            action = "<cmd>RenderMarkdown toggle<CR>";
          }

          # todo-comments
          {
            key = "<leader>td";
            action = "<cmd>TodoLocList<CR>"; # There also is TodoQuickFix, but I dont know the difference
          }

          # Utility
          {
            key = "<leader>q";
            action = "<cmd>quit<CR>";
          }
          {
            key = "<C-e>";
            action = "<cmd>lua vim.diagnostic.open_float()<CR>";
          }

          # Jump to errors
          {
            key = "<leader>ge";
            action = "<cmd>lua vim.diagnostic.goto_next()<CR>";
          }
          {
            key = "<leader>gE";
            action = "<cmd>lua vim.diagnostic.goto_prev()<CR>";
          }

          # Flash
          {
            key = "s";
            action.__raw = ''
              function()
                require'flash'.jump({
              })
              end
            '';
            options.remap = true;
          }
          {
            key = "<C-s>";
            action.__raw = ''
              function()
                require'flash'.toggle({
              })
              end
            '';
            options.remap = true;
          }

          # Diffview (Git Review)
          {
            key = "<leader>gd";
            action = "<cmd>DiffviewOpen<CR>";
            options.desc = "Open Diff View";
          }
          {
            key = "<leader>gx";
            action = "<cmd>DiffviewClose<CR>";
            options.desc = "Close Diff View";
          }
          {
            key = "<leader>gh";
            action = "<cmd>DiffviewFileHistory %<CR>";
            options.desc = "History (Current File)";
          }
          {
            key = "<leader>gH";
            action = "<cmd>DiffviewFileHistory<CR>";
            options.desc = "History (Entire Project)";
          }

          # Git Integration (Gitsigns + Snacks)
          {
            # Toggles the gray "ghost text" at the end of the current line
            key = "<leader>bt";
            action = "<cmd>Gitsigns toggle_current_line_blame<CR>";
            options.desc = "Toggle Git Blame (Line)";
          }
          {
            # PRETTY version: Shows a full blame history popup for the line
            # Uses your existing 'Snacks' plugin
            key = "<leader>bT";
            action.__raw = "function() Snacks.git.blame_line() end";
            options.desc = "Git Blame Popup";
          }
          {
            # Uses Snacks to smartly open the file in GitHub/GitLab
            key = "<leader>bo";
            action.__raw = "function() Snacks.gitbrowse() end";
            options.desc = "Open in Browser";
          }

          # Yazi
          {
            key = "<leader>y";
            action = "<cmd>Yazi<CR>";
          }
          {
            key = "<leader>cw";
            action = "<cmd>Yazi cwd<CR>";
          }

          # 'Manually' trigger WhichKey
          {
            key = "<leader><leader>";
            action = "<cmd>WhichKey <leader><CR>";
            options.desc = "Show all keymaps";
          }

          # Undotree
          {
            key = "<leader>u";
            action = "<cmd>UndotreeToggle<CR>";
            options.desc = "Toggle UndoTree";
          }

          # Oil
          {
            # The "Go Parent Directory" Bind
            key = "-";
            action = "<cmd>Oil<CR>";
            options.desc = "Open Parent Directory";
          }

          # Incremental Rename
          {
            key = "<leader>rn";
            action = ":IncRename "; # Note the space at the end!
            options.desc = "Incremental Rename";
          }

          {
            key = "gd";
            action.__raw = "require('telescope.builtin').lsp_definitions";
            options.desc = "Telescope Goto Definition";
          }
          {
            key = "K";
            action = "<CMD>Lspsaga hover_doc<Enter>";
            options.desc = "Telescope Hover Doc";
          }
          {
            key = "<leader>lx";
            action = "<CMD>LspStop<Enter>";
            options.desc = "Lsp Stop";
          }
          {
            key = "<leader>ls";
            action = "<CMD>LspStart<Enter>";
            options.desc = "Lsp Start";
          }
          {
            key = "<leader>lr";
            action = "<CMD>LspRestart<Enter>";
            options.desc = "Lsp Restart";
          }

          {
            key = "<leader>ao";
            action = "<cmd>AerialToggle! left<CR>";
            options.desc = "Toggle Outline Sidebar";
          }

        ];

      };
    };
}
