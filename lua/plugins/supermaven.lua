return {
	"supermaven-inc/supermaven-nvim",
	config = function()
		require("supermaven-nvim").setup({
			color = {
				suggestion_color = "#6e6e6e", -- change this hex to whatever you want
				cterm = 244,
			},
		})
	end,
}
