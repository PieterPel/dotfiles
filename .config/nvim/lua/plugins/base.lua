return { 
    -- LSP
    --{ 'neovim/nvim-lspconfig' },

    -- Rust
    { 'simrat39/rust-tools.nvim' },

    -- Haskell
    { 'MrcJkb/haskell-tools.nvim', version = '^3', lazy = false },

    -- Autocompletion
    --{ 'hrsh7th/nvim-cmp' }, -- Completion framework
    --{ 'hrsh7th/cmp-nvim-lsp' }, -- LSP completion source:
    -- Useful completion sources:
    --{ 'hrsh7th/cmp-nvim-lua' },
    --{ 'hrsh7th/cmp-nvim-lsp-signature-help' },
    --{ 'hrsh7th/cmp-vsnip' },
    --{ 'hrsh7th/cmp-path' },
    --{ 'hrsh7th/cmp-buffer' },
    --{ 'hrsh7th/vim-vsnip' },

    -- Color scheme
    {
        'bluz71/vim-moonfly-colors',
        name = 'moonfly',
        lazy = false,
        priority = 1000,
    }
}
