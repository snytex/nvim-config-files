return {
	"rachartier/tiny-inline-diagnostic.nvim",
	event = "LspAttach",
	config = function()
		require("tiny-inline-diagnostic").setup({
			preset = "modern", -- Can be: 'modern', 'classic', 'minimal', 'powerline', 'ghost'
			options = {
				show_source = true,
				throttle = 20,
				softwrap = 15,
				multiple_diag_under_cursor = true,
				multilines = true,
				overflow = {
					mode = "wrap",
				},
			},
		})

		-- Disable default virtual text since we're using tiny-inline-diagnostic
		vim.diagnostic.config({ virtual_text = false })
	end,
}
