-- Recommended for nvim-tree
-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Source (old) packer files
require('vars')
require('opts')


-- Lazy plugin manager
require("config.lazy")

require('keys')

-- Completion Plugin Setup
local cmpobj = require'cmp'
cmpobj.setup({
    snippet = { ... }, -- Enable LSP snippets
    mapping = { ... }, -- keyboard shortcuts
    sources = { ... }, -- installed source
    window = { ... }, -- menu layout, symbol for categories
    formatting = { ... }
}) -- end of 'cmp' setup


vim.cmd [[colorscheme moonfly]]
