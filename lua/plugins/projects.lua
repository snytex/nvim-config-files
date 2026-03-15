return {
	"nvim-telescope/telescope.nvim",
	keys = {
		{
			"<leader>p",
			function()
				local pickers = require("telescope.pickers")
				local finders = require("telescope.finders")
				local conf = require("telescope.config").values
				local actions = require("telescope.actions")
				local action_state = require("telescope.actions.state")

				-- Get only top-level directories in ~/Projekte
				local projekte_path = vim.fn.expand("~/Projekte")
				local handle = io.popen("find " .. projekte_path .. " -maxdepth 1 -mindepth 1 -type d")
				local projects = {}

				if handle then
					for dir in handle:lines() do
						table.insert(projects, dir)
					end
					handle:close()
				end

				pickers
					.new({}, {
						prompt_title = "📁 Projekte",
						finder = finders.new_table({
							results = projects,
							entry_maker = function(entry)
								return {
									value = entry,
									display = vim.fn.fnamemodify(entry, ":t"), -- Show only folder name
									ordinal = vim.fn.fnamemodify(entry, ":t"),
									path = entry,
								}
							end,
						}),
						sorter = conf.generic_sorter({}),
						attach_mappings = function(prompt_bufnr, map)
							actions.select_default:replace(function()
								local selection = action_state.get_selected_entry()
								actions.close(prompt_bufnr)
								vim.cmd("cd " .. selection.path)
								vim.cmd("edit .")
							end)
							return true
						end,
					})
					:find()
			end,
			desc = "[P]rojects (~/Projekte)",
		},
	},
}
