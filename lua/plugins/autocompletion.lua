return { -- Autocompletion
	"hrsh7th/nvim-cmp",
	dependencies = {
		{
			"L3MON4D3/LuaSnip",
			build = (function()
				if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
					return
				end
				return "make install_jsregexp"
			end)(),
			dependencies = {
				{
					"rafamadriz/friendly-snippets",
					config = function()
						require("luasnip.loaders.from_vscode").lazy_load()
					end,
				},
			},
		},
		"saadparwaiz1/cmp_luasnip",
		"hrsh7th/cmp-nvim-lsp",
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-path",
	},
	config = function()
		local cmp = require("cmp")
		local luasnip = require("luasnip")
		luasnip.config.setup({})

		-- After a deletion, re-request completions from the LSP so the real
		-- symbols come back instead of the stale fuzzy list cmp was filtering.
		-- Debounced: holding <BS> keeps resetting the timer, so we only refetch
		-- once you pause (no per-keystroke lag), and only inside a word.
		local uv = vim.uv or vim.loop
		local retrigger_timer = nil
		local function retrigger_after_delete()
			if retrigger_timer then
				retrigger_timer:stop()
				retrigger_timer:close()
				retrigger_timer = nil
			end
			retrigger_timer = uv.new_timer()
			retrigger_timer:start(
				120,
				0,
				vim.schedule_wrap(function()
					if retrigger_timer then
						retrigger_timer:stop()
						retrigger_timer:close()
						retrigger_timer = nil
					end
					if not vim.api.nvim_get_mode().mode:match("^i") then
						return
					end
					local col = vim.fn.col(".") - 1
					local before = vim.fn.getline("."):sub(1, col)
					if before:match("[%w_]$") then
						cmp.complete()
					end
				end)
			)
		end

		local kind_icons = {
			Text = "󰉿",
			Method = "m",
			Function = "󰊕",
			Constructor = "",
			Field = "",
			Variable = "󰆧",
			Class = "󰌗",
			Interface = "",
			Module = "",
			Property = "",
			Unit = "",
			Value = "󰎠",
			Enum = "",
			Keyword = "󰌋",
			Snippet = "",
			Color = "󰏘",
			File = "󰈙",
			Reference = "",
			Folder = "󰉋",
			EnumMember = "",
			Constant = "󰇽",
			Struct = "",
			Event = "",
			Operator = "󰆕",
			TypeParameter = "󰊄",
		}

		cmp.setup({
			snippet = {
				expand = function(args)
					luasnip.lsp_expand(args.body)
				end,
			},
			completion = { completeopt = "menu,menuone,noinsert" },

			-- ── Window styling ───────────────────────────────────────────
			window = {
				completion = cmp.config.window.bordered({
					border = "rounded", -- ← change
					winhighlight = "Normal:CmpNormal,CursorLine:CmpSelected,Search:None,FloatBorder:CmpBorder",
					scrollbar = false,
					side_padding = 1,
				}),
				documentation = cmp.config.window.bordered({
					border = "rounded", -- ← change
					winhighlight = "Normal:CmpDocNormal,FloatBorder:CmpBorder",
					scrollbar = false,
				}),
			},
			-- ─────────────────────────────────────────────────────────────

			mapping = cmp.mapping.preset.insert({
				["<C-n>"] = cmp.mapping.select_next_item(),
				["<C-p>"] = cmp.mapping.select_prev_item(),
				["<C-b>"] = cmp.mapping.scroll_docs(-4),
				["<C-f>"] = cmp.mapping.scroll_docs(4),
				["<C-y>"] = cmp.mapping.confirm({ select = true }),
				["<C-Space>"] = cmp.mapping.complete({}),
				["<C-l>"] = cmp.mapping(function()
					if luasnip.expand_or_locally_jumpable() then
						luasnip.expand_or_jump()
					end
				end, { "i", "s" }),
				["<C-h>"] = cmp.mapping(function()
					if luasnip.locally_jumpable(-1) then
						luasnip.jump(-1)
					end
				end, { "i", "s" }),
				["<Tab>"] = cmp.mapping(function(fallback)
					if cmp.visible() then
						if cmp.get_selected_entry() then
							cmp.confirm({ select = false })
						else
							cmp.select_next_item()
						end
					elseif luasnip.expand_or_locally_jumpable() then
						luasnip.expand_or_jump()
					else
						fallback()
					end
				end, { "i", "s" }),
				["<S-Tab>"] = cmp.mapping(function(fallback)
					if cmp.visible() then
						cmp.select_prev_item()
					elseif luasnip.locally_jumpable(-1) then
						luasnip.jump(-1)
					else
						fallback()
					end
				end, { "i", "s" }),

				-- Deleting text re-queries the LSP instead of fuzzy-filtering
				-- the stale candidate list (fixes GL_ARRRD_V → GL_ARR chokepoint).
				["<BS>"] = cmp.mapping(function(fallback)
					fallback()
					retrigger_after_delete()
				end, { "i" }),
				["<C-w>"] = cmp.mapping(function(fallback)
					fallback()
					retrigger_after_delete()
				end, { "i" }),
			}),
			sources = {
				{ name = "lazydev", group_index = 0 },
				{ name = "nvim_lsp" },
				{ name = "luasnip" },
				{ name = "buffer" },
				{ name = "path" },
			},
			-- swap fields order so icon sits after the label
			formatting = {
				fields = { "abbr", "kind", "menu" }, -- ← change
				format = function(entry, vim_item)
					vim_item.kind = string.format(" %s", kind_icons[vim_item.kind])
					vim_item.menu = ({
						nvim_lsp = "[LSP]",
						luasnip = "[Snippet]",
						buffer = "[Buffer]",
						path = "[Path]",
					})[entry.source.name]
					return vim_item
				end,
			},
		})
	end,
}
