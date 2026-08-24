return {
	"vyfor/cord.nvim",
	build = ":Cord update",
	config = function(_, opts)
		local state_file = vim.fn.stdpath("data") .. "/cord_rpc_disabled"

		local function is_disabled()
			return vim.fn.filereadable(state_file) == 1
		end

		local function set_disabled(disabled)
			if disabled then
				vim.fn.writefile({}, state_file)
			else
				vim.fn.delete(state_file)
			end
		end

		-- Re-apply the persisted state once cord is ready. The manager is passed
		-- to the hook directly because cord.server.manager isn't assigned yet at
		-- this point, so require("cord.api.command").hide_presence() would no-op.
		opts.hooks = opts.hooks or {}
		opts.hooks.ready = function(manager)
			if is_disabled() then
				manager:hide()
			end
		end

		require("cord").setup(opts)

		vim.api.nvim_create_user_command("ToggleRPC", function()
			local now_disabled = not is_disabled()
			set_disabled(now_disabled)

			local cmd = require("cord.api.command")
			if now_disabled then
				cmd.hide_presence()
			else
				cmd.show_presence()
			end

			vim.notify("Discord RPC " .. (now_disabled and "disabled" or "enabled"))
		end, { desc = "Toggle Discord RPC" })
	end,
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
