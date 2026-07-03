return {
	"MeanderingProgrammer/render-markdown.nvim",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"echasnovski/mini.icons", -- Optional: or 'nvim-tree/nvim-web-devicons'
	},
	---@module 'render-markdown'
	---@type render.md.UserConfig
	opts = {
		-- You can leave this empty for defaults,
		-- or customize components here
		code = {
			enabled = true,
			style = "language",
			width = "block",
		},
	},
}
