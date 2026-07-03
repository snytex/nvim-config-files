vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("core.options")
require("core.keymaps")
require("core.cpp_autosemicolon").setup()

-- Plugin Manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		error("Error cloning lazy.nvim:\n" .. out)
	end
end

local rtp = vim.opt.rtp
rtp:prepend(lazypath)

-- Remove the greyed-out/dimmed font for "unnecessary" code
vim.api.nvim_set_hl(0, "DiagnosticUnnecessary", {})

-- Remove underlines for warn/hint severity (keeps errors underlined)
vim.diagnostic.config({
	underline = {
		severity = { min = vim.diagnostic.severity.ERROR },
	},
})

-- Plugins
require("lazy").setup({

	require("plugins.colortheme"),
	require("plugins.neotree"),
	require("plugins.bufferline"),
	require("plugins.lualine"),
	require("plugins.treesitter"),
	require("plugins.telescope"),
	require("plugins.lsp"),
	require("plugins.autocompletion"),
	require("plugins.autoformatting"),
	require("plugins.gitsigns"),
	require("plugins.alpha"),
	require("plugins.autopairs"),
	require("plugins.lsp-config"),
	require("plugins.projects"),
	require("plugins.cord"),
	require("plugins.render-markdown"),
	require("plugins.supermaven"),
})
