return {
	"akinsho/bufferline.nvim",
	version = "*",
	dependencies = "nvim-tree/nvim-web-devicons",
	config = function()
		require("bufferline").setup({
			options = {
				mode = "buffers",
				themable = true,
				numbers = "none",
				close_command = "bdelete! %d",
				right_mouse_command = "bdelete! %d",
				left_mouse_command = "buffer %d",
				indicator = {
					icon = "▎",
					style = "icon",
				},
				buffer_close_icon = "󰅖",
				modified_icon = "●",
				close_icon = "",
				left_trunc_marker = "",
				right_trunc_marker = "",
				max_name_length = 18,
				max_prefix_length = 15,
				truncate_names = true,
				tab_size = 18,
				diagnostics = "nvim_lsp",
				diagnostics_update_in_insert = false,
				offsets = {
					{
						filetype = "neo-tree",
						text = "File Explorer",
						text_align = "center",
						separator = true,
					},
				},
				color_icons = true,
				show_buffer_icons = true,
				show_buffer_close_icons = true,
				show_close_icon = true,
				show_tab_indicators = true,
				show_duplicate_prefix = true,
				persist_buffer_sort = true,
				separator_style = "thin", -- changed: angled tabs look much cleaner
				enforce_regular_tabs = false,
				always_show_bufferline = true,
				hover = {
					enabled = true,
					delay = 200,
					reveal = { "close" },
				},
			},
			highlights = {
				fill = {
					bg = "NONE", -- removes the grey slab behind all tabs
				},
				background = {
					bg = "NONE", -- inactive tabs blend into editor bg
					fg = "#6b7280", -- dimmed text for inactive tabs
				},
				buffer_selected = {
					bold = true,
					italic = false, -- active tab: bold, no italic weirdness
				},
				buffer_visible = {
					bg = "NONE",
					fg = "#6b7280",
				},
				separator = {
					bg = "NONE",
					fg = "NONE",
				},
				separator_selected = {
					bg = "NONE",
					fg = "NONE",
				},
				separator_visible = {
					bg = "NONE",
					fg = "NONE",
				},
				indicator_selected = {
					bg = "NONE",
				},
				offset_separator = {
					bg = "NONE",
				},
			},
		})
	end,
}
