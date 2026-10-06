return {
	"sphamba/smear-cursor.nvim",
	event = "VeryLazy",
	-- Skips loading entirely if you use a GUI like Neovide that has built-in smooth cursors
	cond = vim.g.neovide == nil,
	opts = {
		-- Only meant for setups without termguicolors, and the plugin says not to
		-- combine it with never_draw_over_target = false (the default).
		hide_target_hack = false,
		cursor_color = "none", -- smear takes the syntax color of the text under the cursor

		-- Your Preferences
		smear_between_buffers = true,
		smear_between_neighbor_lines = true,
		scroll_buffer_space = true,
		legacy_computing_symbols_support = false,
		smear_insert_mode = true,
	},
	config = function(_, opts)
		require("smear_cursor").setup(opts)

		-- The smear only exists while the cursor travels; at rest the terminal
		-- draws its own cursor. Point that one at the `Cursor` group (kitty
		-- honours the color change) and keep the group on the syntax color too.
		vim.o.guicursor = "n-v-c-sm:block-Cursor,i-ci-ve:ver25-Cursor,r-cr-o:hor20-Cursor,t:block-blinkon500-blinkoff500-TermCursor"

		local color = require("smear_cursor.color")
		local last
		local function sync_cursor_color()
			local fg = color.get_color_at_cursor()
			if not fg then
				local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
				fg = normal.fg and string.format("#%06x", normal.fg) or "#d4d4d4"
			end
			if fg ~= last then
				last = fg
				vim.api.nvim_set_hl(0, "Cursor", { bg = fg, fg = "#1e1e1e" })
			end
		end

		vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "ModeChanged", "BufEnter", "ColorScheme" }, {
			group = vim.api.nvim_create_augroup("syntax-cursor-color", { clear = true }),
			callback = function(ev)
				if ev.event == "ColorScheme" then
					last = nil
				end
				sync_cursor_color()
			end,
		})
		sync_cursor_color()
	end,
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
