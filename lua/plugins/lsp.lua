return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		{ "j-hui/fidget.nvim", opts = {} },
		{ "folke/neodev.nvim", opts = {} },
	},
	config = function()
		vim.filetype.add({
			extension = {
				vert = "glsl",
				frag = "glsl",
				geom = "glsl",
				tesc = "glsl",
				tese = "glsl",
				comp = "glsl",
			},
		})

		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
			callback = function(event)
				local map = function(keys, func, desc)
					vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
				end

				-- Jump to definition/references/etc
				map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
				map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
				map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
				map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")
				map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
				map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")
				map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
				map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
				map("K", vim.lsp.buf.hover, "Hover Documentation")
				map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

				vim.keymap.set(
					"i",
					"<C-k>",
					vim.lsp.buf.signature_help,
					{ buffer = event.buf, desc = "LSP: Signature Help" }
				)

				vim.api.nvim_create_autocmd("TextChangedI", {
					buffer = event.buf,
					callback = function()
						local client = vim.lsp.get_client_by_id(event.data.client_id)
						if not client or not client.server_capabilities.signatureHelpProvider then
							return
						end
						local col = vim.api.nvim_win_get_cursor(0)[2]
						local char_before = vim.api.nvim_get_current_line():sub(col, col)
						if char_before == "(" or char_before == "," then
							vim.lsp.buf.signature_help()
						end
					end,
				})

				-- Highlight references under cursor
				local client = vim.lsp.get_client_by_id(event.data.client_id)
				if client and client.server_capabilities.documentHighlightProvider then
					vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
						buffer = event.buf,
						callback = vim.lsp.buf.document_highlight,
					})
					vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
						buffer = event.buf,
						callback = vim.lsp.buf.clear_references,
					})
				end
			end,
		})

		local capabilities = vim.lsp.protocol.make_client_capabilities()
		capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

		-- LSP servers to install and configure
		local servers = {
			rust_analyzer = {
				settings = {
					["rust-analyzer"] = {
						cargo = { allFeatures = true },
						checkOnSave = { command = "clippy" },
						inlayHints = {
							bindingModeHints = { enable = true },
							chainingHints = { enable = true },
							closureReturnTypeHints = { enable = "always" },
							parameterHints = { enable = true },
							typeHints = { enable = true },
						},
					},
				},
			},
			jdtls = {},
			clangd = {
				cmd = {
					"clangd",
					"--background-index",
					"--clang-tidy",
					"--header-insertion=iwyu",
					"--completion-style=detailed",
					"--function-arg-placeholders=0",
					"--fallback-style=llvm",
				},
				init_options = {
					usePlaceholders = false,
					completeUnimported = true,
					clangdFileStatus = true,
				},
			},
			lua_ls = {
				settings = {
					Lua = {
						completion = {
							callSnippet = "Replace",
						},
						diagnostics = {
							globals = { "vim" },
						},
					},
				},
			},
			pyright = {
				settings = {
					python = {
						analysis = {
							typeCheckingMode = "basic",
							autoSearchPaths = true,
							useLibraryCodeForTypes = true,
						},
					},
				},
			},
			omnisharp = {
				settings = {
					FormattingOptions = {
						EnableEditorConfigSupport = true,
						OrganizeImports = true,
					},
					MsBuild = {
						LoadProjectsOnDemand = false,
					},
					RoslynExtensionsOptions = {
						EnableAnalyzersSupport = true,
						EnableImportCompletion = true,
						InlayHintsOptions = {
							EnableForParameters = true,
							ForLiteralParameters = true,
							ForIndexerParameters = true,
							ForObjectCreationParameters = true,
							ForOtherParameters = true,
							EnableForTypes = true,
							ForImplicitVariableTypes = true,
							ForLambdaParameterTypes = true,
							ForImplicitObjectCreation = true,
						},
					},
				},
			},
		}

		require("mason").setup()

		local ensure_installed = vim.tbl_keys(servers or {})
		vim.list_extend(ensure_installed, {
			"rust-analyzer",
			"stylua",
			"clang-format",
			"google-java-format",
			"black",
			"isort",
			"csharpier",
			"netcoredbg",
		})

		require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

		-- Neovim 0.11+ / mason-lspconfig v2: the old `handlers` API is gone.
		-- Register configs via vim.lsp.config and let mason-lspconfig auto-enable them.
		vim.lsp.config("*", { capabilities = capabilities })
		for server_name, server in pairs(servers) do
			vim.lsp.config(server_name, server)
		end

		require("mason-lspconfig").setup({})

		-- asm_lsp is not in mason, set it up directly
		vim.lsp.config("asm_lsp", {
			cmd = { vim.fn.expand("~/.cargo/bin/asm-lsp") },
			capabilities = capabilities,
			filetypes = { "asm", "s", "S" },
		})
		vim.lsp.enable("asm_lsp")

		-- glsl_analyzer is not in mason, set it up directly
		vim.lsp.config("glsl_analyzer", {
			cmd = { "glsl_analyzer" },
			capabilities = capabilities,
			filetypes = { "glsl", "vert", "frag", "geom", "tesc", "tese", "comp" },
			on_attach = function(client, _)
				client.server_capabilities.signatureHelpProvider = nil
			end,
		})
		vim.lsp.enable("glsl_analyzer")
	end,
}
