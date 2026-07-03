return {
	"goolord/alpha-nvim",
	event = "VimEnter",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local alpha = require("alpha")
		local dashboard = require("alpha.themes.dashboard")

		-- Neovim ASCII art
		dashboard.section.header.val = {
			[[                                                                   ]],
			[[                                                                   ]],
			[[                                                                   ]],
			[[ ██████   █████                                ███                 ]],
			[[░░██████ ░░███                                ░░░                  ]],
			[[ ░███░███ ░███   ██████   ██████  █████ █████ ████  █████████████  ]],
			[[ ░███░░███░███  ███░░███ ███░░███░░███ ░░███ ░░███ ░░███░░███░░███ ]],
			[[ ░███ ░░██████ ░███████ ░███ ░███ ░███  ░███  ░███  ░███ ░███ ░███ ]],
			[[ ░███  ░░█████ ░███░░░  ░███ ░███ ░░███ ███   ░███  ░███ ░███ ░███ ]],
			[[ █████  ░░█████░░██████ ░░██████   ░░█████    █████ █████░███ █████]],
			[[░░░░░    ░░░░░  ░░░░░░   ░░░░░░     ░░░░░    ░░░░░ ░░░░░ ░░░ ░░░░░ ]],
			[[                                                                   ]],
			[[                                                                   ]],
			[[                                                                   ]],
		}

		-- Buttons
		dashboard.section.buttons.val = {
			dashboard.button("n", "  New file", ":enew <BAR> startinsert <CR>"),
			dashboard.button("f", "  Find file", ":Telescope find_files <CR>"),
			dashboard.button("r", "  Recent files", ":Telescope oldfiles <CR>"),
			dashboard.button(
				"p",
				"  Projects",
				':lua require("telescope.pickers").new({}, { prompt_title = "📁 Projekte", finder = require("telescope.finders").new_table({ results = vim.fn.systemlist("find ~/Projekte -maxdepth 1 -mindepth 1 -type d"), entry_maker = function(e) return { value = e, display = vim.fn.fnamemodify(e, ":t"), ordinal = vim.fn.fnamemodify(e, ":t"), path = e } end }), sorter = require("telescope.config").values.generic_sorter({}), attach_mappings = function(b, m) require("telescope.actions").select_default:replace(function() local s = require("telescope.actions.state").get_selected_entry() require("telescope.actions").close(b) vim.cmd("cd " .. s.path) vim.cmd("edit .") end) return true end }):find()<CR>'
			),
			dashboard.button("g", "  Find text", ":Telescope live_grep <CR>"),
			dashboard.button("l", "  Lazy", ":Lazy<CR>"),
			dashboard.button("q", "  Quit", ":qa<CR>"),
		}

		-- Footer with Cava indicator
		local function footer()
			local total_plugins = require("lazy").stats().count
			local datetime = os.date(" %d-%m-%Y   %H:%M:%S")
			return datetime .. "   " .. total_plugins .. " plugins"
		end

		dashboard.section.footer.val = footer()

		alpha.setup(dashboard.opts)

		-- Disable folding on alpha buffer
		vim.cmd([[autocmd FileType alpha setlocal nofoldenable]])
	end,
}
