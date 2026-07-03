return {
	"mfussenegger/nvim-dap",
	dependencies = {
		"rcarriga/nvim-dap-ui",
		"nvim-neotest/nvim-nio",
		"theHamsta/nvim-dap-virtual-text",
	},
	keys = {
		{ "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "[D]ebug [B]reakpoint" },
		{ "<leader>dc", function() require("dap").continue() end,          desc = "[D]ebug [C]ontinue" },
		{ "<leader>dn", function() require("dap").step_over() end,         desc = "[D]ebug [N]ext (step over)" },
		{ "<leader>di", function() require("dap").step_into() end,         desc = "[D]ebug Step [I]nto" },
		{ "<leader>do", function() require("dap").step_out() end,          desc = "[D]ebug Step [O]ut" },
		{ "<leader>dr", function() require("dap").repl.open() end,         desc = "[D]ebug [R]EPL" },
		{ "<leader>du", function() require("dapui").toggle() end,          desc = "[D]ebug [U]I" },
		{ "<leader>dq", function() require("dap").terminate() end,         desc = "[D]ebug [Q]uit" },
	},
	config = function()
		local dap = require("dap")
		local dapui = require("dapui")

		require("nvim-dap-virtual-text").setup()

		dapui.setup()

		dap.listeners.before.attach.dapui_config = function() dapui.open() end
		dap.listeners.before.launch.dapui_config = function() dapui.open() end
		dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
		dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

		-- C# via netcoredbg
		dap.adapters.coreclr = {
			type = "executable",
			command = vim.fn.stdpath("data") .. "/mason/bin/netcoredbg",
			args = { "--interpreter=vscode" },
		}

		dap.configurations.cs = {
			{
				type = "coreclr",
				name = "Launch (netcoredbg)",
				request = "launch",
				program = function()
					return vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/bin/Debug/", "file")
				end,
			},
			{
				type = "coreclr",
				name = "Attach (netcoredbg)",
				request = "attach",
				processId = require("dap.utils").pick_process,
			},
		}

		-- Breakpoint styling
		vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DiagnosticError", linehl = "", numhl = "" })
		vim.fn.sign_define("DapBreakpointCondition", { text = "", texthl = "DiagnosticWarn", linehl = "", numhl = "" })
		vim.fn.sign_define("DapStopped", { text = "", texthl = "DiagnosticInfo", linehl = "DiffAdd", numhl = "" })
	end,
}
