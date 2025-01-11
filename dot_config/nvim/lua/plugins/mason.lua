local M = {
	'williamboman/mason.nvim',
	dependencies = {
      'williamboman/mason-lspconfig.nvim',
      'nvim-lua/plenary.nvim',
	},
}

M.servers = {
	"lua_ls",
	"rust_analyzer",
	"clangd",
    "hls",
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
	
	require("lsp-zero").setup()
	require("mason").setup()
	
	require("mason-lspconfig").setup_handlers {
		function (server_name)
		    require "lspconfig" [server_name].setup {}
		end
	}
	
	require("mason-lspconfig").setup {
      ensure_installed = M.servers,
      automatic_installation = true,
	}

end

return M
