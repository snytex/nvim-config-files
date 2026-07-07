return {
	"hedyhli/outline.nvim",
	cmd = { "Outline", "OutlineOpen" },
	keys = {
		{ "<leader>o", "<cmd>Outline<CR>", desc = "Toggle symbol outline" },
	},
	opts = {
		outline_window = {
			position = "right",
			width = 25,
			auto_close = false,
			show_numbers = false,
			show_relative_numbers = false,
		},
		outline_items = {
			show_symbol_details = true,
		},
		symbol_folding = {
			autofold_depth = 1,
		},
		preview_window = {
			auto_preview = false,
		},
	},
}
