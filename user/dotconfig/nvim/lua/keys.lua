vim.api.nvim_buf_set_keymap(0, 'n', '<C-]>',
    '<cmd>lua vim.lsp.buf.definition()<CR>',
    { noremap = true, silent = true})

-- nvim-tree
-- Toggle nvim-tree window
vim.api.nvim_set_keymap('n', '<C-n>', ':NvimTreeToggle<CR>', {noremap = true, silent = true})

-- Find current file in nvim-tree
vim.api.nvim_set_keymap('n', '<leader>r', ':NvimTreeFindFile<CR>', {noremap = true, silent = true})

-- Refresh nvim-tree
vim.api.nvim_set_keymap('n', '<leader>r', ':NvimTreeRefresh<CR>', {noremap = true, silent = true})

-- telescope
--local builtin = require('telescope.builtin')
--vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
--vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
--vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
--vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})

-- fugitive
vim.keymap.set("n", "<leader>gs", vim.cmd.Git)

-- harpoon
local mark = require "harpoon.mark"
local ui = require "harpoon.ui"
local term = require "harpoon.term"
vim.keymap.set("n", "<leader>e", ui.toggle_quick_menu, {})
vim.keymap.set("n", "<leader>a", mark.add_file, {})
vim.keymap.set("n", "<C-j>", ui.nav_next, {})
vim.keymap.set("n", "<C-k>", ui.nav_prev, {})
vim.keymap.set("n", "<C-t>", function()
   term.gotoTerminal(1)
end)

--- undotree
vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)

-- lsp
vim.keymap.set("n", "gd", vim.lsp.buf.definition)
vim.keymap.set("n", "K", vim.lsp.buf.hover)
vim.keymap.set("n", "<leader>vws", vim.lsp.buf.workspace_symbol)
vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float)
vim.keymap.set("n", "[d", vim.diagnostic.goto_next)
vim.keymap.set("n", "]d", vim.diagnostic.goto_prev)
vim.keymap.set("n", "<leader>vca", vim.lsp.buf.code_action)
vim.keymap.set("n", "<leader>vrr", vim.lsp.buf.references)
vim.keymap.set("n", "<leader>vrn", vim.lsp.buf.rename)
