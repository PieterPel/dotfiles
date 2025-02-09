local M = {
    'VonHeikemen/lsp-zero.nvim',
    branch = "v1.x",
    dependencies = {
        'neovim/nvim-lspconfig',
        'hrsh7th/nvim-cmp',
        'hrsh7th/cmp-buffer',
        'hrsh7th/cmp-path',
        'hrsh7th/cmp-nvim-lsp',
        'hrsh7th/cmp-nvim-lua',
        'saadparwaiz1/cmp_luasnip',
        'L3MON4D3/LuaSnip',
        'rafamadriz/friendly-snippets',
        'williamboman/mason.nvim',
        'williamboman/mason-lspconfig.nvim',
        'nvim-lua/plenary.nvim',
    },
}

M.servers = {
    "lua_ls",
    "rust_analyzer",
    "clangd",
    "pyright",
}

function M.config()
    local lsp = require("lsp-zero")
    lsp.preset("recommended")

    lsp.set_preferences({
        sign_icons = {
            error = 'E',
            warn = 'W',
            hint = 'H',
            info = 'I'
        }
    })

    lsp.configure('lua_ls', {
      cmd = { 'lua-language-server' },
      settings = {
        Lua = {
          runtime = {
            version = 'LuaJIT',
            path = vim.split(package.path, ';'),
          },
          diagnostics = {
            globals = { 'vim' },
          },
        },
      },
    })

    -- Configure luasnip
    local luasnip = require('luasnip')
    luasnip.config.setup {}

    -- Configure cmp
    local cmp = require('cmp')
    cmp.setup {
        snippet = {
            expand = function(args)
                luasnip.lsp_expand(args.body) -- For vsnip users.
            end,
        },
        mapping = {
            ['<C-d>'] = cmp.mapping.scroll_docs(-4),
            ['<C-f>'] = cmp.mapping.scroll_docs(4),
            ['<C-Space>'] = cmp.mapping.complete {}, -- Trigger completion
            ['<CR>'] = cmp.mapping.confirm {
                behavior = cmp.ConfirmBehavior.Replace,
                select = true,
            },
            ['<Tab>'] = cmp.mapping(function(fallback)
                if cmp.visible() then
                    cmp.select_next_item()
                elseif luasnip.expand_or_jumpable() then
                    luasnip.expand_or_jump()
                else
                    fallback()
                end
            end, { 'i', 's' }),
            ['<S-Tab>'] = cmp.mapping(function(fallback)
                if cmp.visible() then
                    cmp.select_prev_item()
                elseif luasnip.jumpable(-1) then
                    luasnip.jump(-1)
                else
                    fallback()
                end
            end, { 'i', 's' }),
        },
        sources = {
            { name = 'nvim_lsp' },
            { name = 'luasnip' },
            { name = 'buffer' },
            { name = 'path' },
        },
        experimental = {
            ghost_text = true, -- Show ghost text for better visibility
        },
    }

    -- Setup Mason
    require("mason").setup()

    require("mason-lspconfig").setup {
        ensure_installed = M.servers,
        automatic_installation = true,
    }

    require("mason-lspconfig").setup_handlers {
        function (server_name)
            require("lspconfig")[server_name].setup(lsp.build_options(server_name, {}))
        end
    }

    lsp.setup()
end

return M
