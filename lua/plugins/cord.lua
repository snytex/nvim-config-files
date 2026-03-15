return {
	"vyfor/cord.nvim",
	build = ":Cord update",
	opts = {
		usercmds = true,
		display = {
			theme = "default",
			flavor = "dark",
		},
		idle = {
			enabled = true,
			timeout = 300000,
			details = "Idling",
		},
		text = {
			viewing = function(opts)
				return "Viewing " .. opts.filename
			end,
			editing = function(opts)
				return "Editing " .. opts.filename
			end,
			workspace = function(opts)
				return "In " .. opts.workspace
			end,
			file_browser = function(opts)
				return "Browsing files in " .. opts.tooltip
			end,
			plugin_manager = function(opts)
				return "Managing plugins in " .. opts.tooltip
			end,
		},
	},
}
