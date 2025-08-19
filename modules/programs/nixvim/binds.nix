{ ...
}:

{
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
  ];
}
