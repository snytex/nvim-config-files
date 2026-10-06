return { -- Highlight, edit, and navigate code
	-- The `main` branch is a rewrite: it only installs parsers. It ignores the
	-- old `highlight`/`indent`/`ensure_installed` opts, so highlighting and
	-- indent are started per buffer in the FileType autocmd below.
	-- Building parsers needs the tree-sitter CLI (`pacman -S tree-sitter-cli`).
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	build = ":TSUpdate",
	config = function()
		local ts = require("nvim-treesitter")

		local ensure_installed = {
			"rust",
			"asm",
			"c",
			"cpp",
			"lua",
			"python",
			"javascript",
			"typescript",
			"vimdoc",
			"vim",
			"regex",
			"terraform",
			"sql",
			"dockerfile",
			"toml",
			"json",
			"java",
			"groovy",
			"go",
			"gitignore",
			"graphql",
			"yaml",
			"make",
			"cmake",
			"markdown",
			"markdown_inline",
			"bash",
			"tsx",
			"css",
			"html",
			"c_sharp",
			"glsl",
		}

		-- Treesitter indent fights Allman braces and namespace bodies; the
		-- built-in cindent already matches the clang-format style for these.
		local keep_builtin_indent = { c = true, cpp = true }
		local regex_highlight_too = { ruby = true }

		local function attach(buf, lang)
			if not pcall(vim.treesitter.start, buf, lang) then
				return false
			end
			if regex_highlight_too[vim.bo[buf].filetype] then
				vim.bo[buf].syntax = "on"
			end
			if not keep_builtin_indent[vim.bo[buf].filetype] then
				vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
			end
			return true
		end

		-- Re-attach every open buffer once a parser it was missing gets built.
		local function attach_all()
			vim.schedule(function()
				for _, buf in ipairs(vim.api.nvim_list_bufs()) do
					local ft = vim.bo[buf].filetype
					if vim.api.nvim_buf_is_loaded(buf) and ft ~= "" and not vim.treesitter.highlighter.active[buf] then
						local lang = vim.treesitter.language.get_lang(ft)
						if lang then
							attach(buf, lang)
						end
					end
				end
			end)
		end

		-- Without the CLI every startup would re-download all grammars and then
		-- fail to compile them, so warn once instead.
		local have_cli = vim.fn.executable("tree-sitter") == 1
		if have_cli then
			-- Async, and a no-op for parsers that are already installed.
			ts.install(ensure_installed):await(attach_all)
		else
			vim.schedule(function()
				vim.notify("treesitter: install tree-sitter-cli to build parsers", vim.log.levels.WARN)
			end)
		end

		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("treesitter-start", { clear = true }),
			callback = function(ev)
				local lang = vim.treesitter.language.get_lang(ev.match)
				if not lang or attach(ev.buf, lang) or vim.tbl_contains(ensure_installed, lang) then
					return
				end
				-- Unlisted language with an available parser: the old `auto_install`.
				if have_cli and vim.tbl_contains(ts.get_available(), lang) then
					ts.install(lang):await(attach_all)
				end
			end,
		})
	end,
}
