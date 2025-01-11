vim.opt.completeopt = {'menuone', 'noselect', 'noinsert'}

-- Recommended settings from https://builtin.com/software-engineering-perspectives/neovim-configuration
-- Disable compatibility to old-time vi
vim.opt.compatible = false

-- Show matching parentheses
vim.opt.showmatch = true

-- Case insensitive searching
vim.opt.ignorecase = true

-- Enable mouse support
vim.opt.mouse = 'a'

-- Highlight search results
vim.opt.hlsearch = true

-- Incremental search
vim.opt.incsearch = true

-- Set tab-related options
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true
vim.opt.shiftwidth = 4

-- Auto-indent new lines
vim.opt.autoindent = true

-- Display line numbers
vim.opt.number = true

-- Bash-like tab completion
vim.opt.wildmode = { 'longest', 'list' }

-- Set an 80-column border
vim.opt.colorcolumn = '80'

-- Enable file type plugins and indentation
vim.cmd('filetype plugin indent on')

-- Enable syntax highlighting
vim.cmd('syntax on')

-- Use system clipboard
vim.opt.clipboard = 'unnamedplus'

-- Highlight the current cursor line
vim.opt.cursorline = true

-- Speed up scrolling
vim.opt.ttyfast = true

-- Optionally enable spell check (uncomment to use)
-- vim.opt.spell = true

-- Optionally disable swap file creation (uncomment to use)
-- vim.opt.swapfile = false

-- Optionally set backup directory (uncomment and set path to use)
-- vim.opt.backupdir = vim.fn.stdpath('cache') .. '/vim'


-- Own adjustments
vim.wo.relativenumber = true

vim.opt.termguicolors = true
