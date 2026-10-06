return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>f",
			function()
				require("conform").format({ async = true, lsp_fallback = true })
			end,
			mode = "",
			desc = "[F]ormat buffer",
		},
	},
	opts = {
		notify_on_error = false,
		format_on_save = function(bufnr)
			-- Disable with a global or buffer-local variable
			if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
				return
			end
			return {
				timeout_ms = 500,
				lsp_fallback = true,
			}
		end,
		formatters_by_ft = {
			lua = { "stylua" },
			python = { "ruff_format" },
			javascript = { "prettierd", "prettier", stop_after_first = true },
			typescript = { "prettierd", "prettier", stop_after_first = true },
			javascriptreact = { "prettierd", "prettier", stop_after_first = true },
			typescriptreact = { "prettierd", "prettier", stop_after_first = true },
			json = { "prettierd", "prettier", stop_after_first = true },
			html = { "prettierd", "prettier", stop_after_first = true },
			css = { "prettierd", "prettier", stop_after_first = true },
			yaml = { "prettierd", "prettier", stop_after_first = true },
			markdown = { "prettierd", "prettier", stop_after_first = true },
			go = { "goimports", "gofmt" },
			terraform = { "terraform_fmt" },
			sql = { "sql_formatter" },
			sh = { "shfmt" },
			c = { "clang-format" },
			cpp = { "clang-format" },
			java = { "google-java-format" },
			-- Explicit, so loose .rs files format too instead of relying on the
			-- rust-analyzer LSP fallback, which needs a cargo workspace.
			rust = { "rustfmt" },
		},
		-- Formatters that don't already default to two spaces. Without these the
		-- format-on-save above rewrites the file and undoes the editor settings.
		-- (prettier, clang-format/LLVM, google-java-format, terraform_fmt and
		-- sql_formatter are all 2 by default; gofmt is hard tabs and unconfigurable.)
		formatters = {
			stylua = {
				prepend_args = { "--indent-type", "Spaces", "--indent-width", "2" },
			},
			ruff_format = {
				prepend_args = { "--config", "indent-width = 2" },
			},
			shfmt = {
				prepend_args = { "-i", "2" },
			},
			-- Allman braces are a nightly-only rustfmt option, and /usr/bin/rustfmt
			-- is Arch's stable build, which silently warns and ignores them. This is
			-- the rustup shim; "+nightly" is explicit so it survives a default-
			-- toolchain change. Style itself lives in ~/.config/rustfmt/rustfmt.toml.
			rustfmt = {
				command = vim.fn.expand("~/.cargo/bin/rustfmt"),
				prepend_args = { "+nightly" },
			},
			["clang-format"] = {
				prepend_args = { "--style", "file" },
			},
		},
	},
}
