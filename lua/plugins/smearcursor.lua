return {
	"sphamba/smear-cursor.nvim",
	event = "VeryLazy",
	-- Skips loading entirely if you use a GUI like Neovide that has built-in smooth cursors
	cond = vim.g.neovide == nil,
	opts = {
		-- Upgrades & Fixes
		hide_target_hack = true, -- Prevents the real cursor from glitching through the smear
		cursor_color = "none", -- Automatically matches your active colorscheme

		-- Your Preferences
		smear_between_buffers = true,
		smear_between_neighbor_lines = true,
		scroll_buffer_space = true,
		legacy_computing_symbols_support = false,
		smear_insert_mode = true,
	},
	specs = {
		-- Automatically disables conflicting cursor animations if you use mini.animate
		{
			"nvim-mini/mini.animate",
			optional = true,
			opts = {
				cursor = { enable = false },
			},
		},
	},
}
