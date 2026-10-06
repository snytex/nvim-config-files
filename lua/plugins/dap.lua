return {
	"mfussenegger/nvim-dap",
	dependencies = {
		"rcarriga/nvim-dap-ui",
		"nvim-neotest/nvim-nio",
		"theHamsta/nvim-dap-virtual-text",
	},
	-- <leader>do stays the diagnostics toggle (core/keymaps.lua), so step-out is <leader>dO
	keys = {
		{ "<F5>", function() require("dap").continue() end, desc = "Debug: Start/Continue" },
		{ "<F10>", function() require("dap").step_over() end, desc = "Debug: Step Over" },
		{ "<F11>", function() require("dap").step_into() end, desc = "Debug: Step Into" },
		{ "<F12>", function() require("dap").step_out() end, desc = "Debug: Step Out" },
		{ "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "[D]ebug [B]reakpoint" },
		{ "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Condition: ")) end, desc = "[D]ebug conditional [B]reakpoint" },
		{ "<leader>dc", function() require("dap").continue() end, desc = "[D]ebug [C]ontinue" },
		{ "<leader>dl", function() require("dap").run_last() end, desc = "[D]ebug run [L]ast" },
		{ "<leader>dn", function() require("dap").step_over() end, desc = "[D]ebug [N]ext (step over)" },
		{ "<leader>di", function() require("dap").step_into() end, desc = "[D]ebug Step [I]nto" },
		{ "<leader>dO", function() require("dap").step_out() end, desc = "[D]ebug Step [O]ut" },
		{ "<leader>dr", function() require("dap").repl.open() end, desc = "[D]ebug [R]EPL" },
		{ "<leader>du", function() require("dapui").toggle() end, desc = "[D]ebug [U]I" },
		{ "<leader>dq", function() require("dap").terminate() end, desc = "[D]ebug [Q]uit" },
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

		-- C/C++ (and Rust) via gdb's built-in DAP mode (gdb >= 14), no extra adapter
		dap.adapters.gdb = {
			type = "executable",
			command = "gdb",
			args = { "--interpreter=dap", "--eval-command", "set print pretty on" },
		}

		-- Remember the last binary so re-launching is just <CR>
		local last_program = nil
		local function pick_program()
			last_program = vim.fn.input("Path to executable: ", last_program or (vim.fn.getcwd() .. "/"), "file")
			return last_program
		end

		dap.configurations.cpp = {
			{
				name = "Launch (gdb)",
				type = "gdb",
				request = "launch",
				program = pick_program,
				cwd = "${workspaceFolder}",
				stopAtBeginningOfMainSubprogram = false,
			},
			{
				name = "Launch with arguments (gdb)",
				type = "gdb",
				request = "launch",
				program = pick_program,
				args = function()
					return vim.split(vim.fn.input("Arguments: "), " ", { trimempty = true })
				end,
				cwd = "${workspaceFolder}",
				stopAtBeginningOfMainSubprogram = false,
			},
			{
				name = "Attach to process (gdb)",
				type = "gdb",
				request = "attach",
				pid = require("dap.utils").pick_process,
				cwd = "${workspaceFolder}",
			},
		}
		dap.configurations.c = dap.configurations.cpp
		dap.configurations.rust = dap.configurations.cpp

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
