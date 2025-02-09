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

vim.cmd [[colorscheme moonfly]]
