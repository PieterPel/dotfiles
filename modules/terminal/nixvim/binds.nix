{
  flake.modules.homeManager.nixvim-binds = { config, lib, ... }: {
    config = lib.mkIf config.modules.terminal.nixvim.enable {
      programs.nixvim.keymaps = [
        # Disable arrow keys
        {
          key = "<up>";
          action = "<nop>";
          mode = [ "n" "i" "v" ];
        }
        {
          key = "<down>";
          action = "<nop>";
          mode = [ "n" "i" "v" ];
        }
        {
          key = "<left>";
          action = "<nop>";
          mode = [ "n" "i" "v" ];
        }
        {
          key = "<right>";
          action = "<nop>";
          mode = [ "n" "i" "v" ];
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
          action.__raw = "function() require('harpoon.mark').add_file() end";
          options.desc = "Add file to harpoon";
        }
        {
          key = "<leader>m";
          action.__raw = "function() require('harpoon.ui').toggle_quick_menu() end";
          options.desc = "Toggle harpoon menu";
        }
        {
          key = "<leader>1";
          action.__raw = "function() require('harpoon.ui').nav_file(1) end";
          options.desc = "Navigate to harpoon file 1";
        }
        {
          key = "<leader>2";
          action.__raw = "function() require('harpoon.ui').nav_file(2) end";
          options.desc = "Navigate to harpoon file 2";
        }
        {
          key = "<leader>3";
          action.__raw = "function() require('harpoon.ui').nav_file(3) end";
          options.desc = "Navigate to harpoon file 3";
        }
        {
          key = "<leader>4";
          action.__raw = "function() require('harpoon.ui').nav_file(4) end";
          options.desc = "Navigate to harpoon file 4";
        }
        {
          key = "<C-n>";
          action.__raw = "function() require('harpoon.ui').nav_next() end";
          options.desc = "Navigate to next harpoon file";
        }
        {
          key = "<C-p>";
          action.__raw = "function() require('harpoon.ui').nav_prev() end";
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

        # Copilot Chat
        {
          key = "<leader>co";
          action = "<cmd>CopilotChatOpen<CR>";
        }
        {
          key = "<leader>cc";
          action = "<cmd>CopilotChatClose<CR>";
        }
        {
          key = "<leader>cp";
          action = "<cmd>CopilotChatToggle<CR>";
        }
        {
          key = "<leader>cg";
          action = "<cmd>Gemini toggle<CR>";
        }

        # Opencode
        {
          key = "<leader>oA";
          action.__raw = "function() require('opencode').ask() end";
          options.desc = "Ask opencode";
        }
        {
          key = "<leader>oa";
          action.__raw = "function() require('opencode').ask('@cursor: ') end";
          options.desc = "Ask opencode about this";
          mode = "n";
        }
        {
          key = "<leader>oa";
          action.__raw = "function() require('opencode').ask('@selection: ') end";
          options.desc = "Ask opencode about selection";
          mode = "v";
        }
        {
          key = "<leader>ot";
          action.__raw = "function() require('opencode').toggle() end";
          options.desc = "Toggle embedded opencode";
        }
        {
          key = "<leader>on";
          action.__raw = "function() require('opencode').command('session_new') end";
          options.desc = "New session";
        }
        {
          key = "<leader>oy";
          action.__raw = "function() require('opencode').command('messages_copy') end";
          options.desc = "Copy last message";
        }
        {
          key = "<S-C-u>";
          action.__raw = "function() require('opencode').command('messages_half_page_up') end";
          options.desc = "Scroll messages up";
        }
        {
          key = "<S-C-d>";
          action.__raw = "function() require('opencode').command('messages_half_page_down') end";
          options.desc = "Scroll messages down";
        }
        {
          key = "<leader>op";
          action.__raw = "function() require('opencode').select_prompt() end";
          options.desc = "Select prompt";
          mode = [ "n" "v" ];
        }

        # LazyGit
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
          key = "<C-e";
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

        # Git-blame
        {
          key = "<leader>bt";
          action = "<cmd>GitBlameToggle<CR>";
        }
        {
          key = "<leader>bo";
          action = "<cmd>GitBlameOpenFileURL<CR>";
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
      ];
    };
  };
}
