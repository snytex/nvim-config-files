return {
	"Mofiqul/vscode.nvim",
	priority = 1000,
	config = function()
		require("vscode").setup({
			style = "dark",
			transparent = true,
			italic_comments = true,
		})
		vim.cmd.colorscheme("vscode")

		vim.api.nvim_set_hl(0, "BufferLineFill", { bg = "NONE" })
		vim.api.nvim_set_hl(0, "BufferLineBackground", { bg = "NONE", fg = "#555555" })
		vim.api.nvim_set_hl(0, "BufferLineBufferSelected", { fg = "#ffffff", bold = true })
		vim.api.nvim_set_hl(0, "BufferLineBufferVisible", { bg = "NONE", fg = "#555555" })
		vim.api.nvim_set_hl(0, "BufferLineIndicatorSelected", { fg = "#569cd6", bg = "NONE" })
		vim.api.nvim_set_hl(0, "BufferLineSeparator", { fg = "NONE", bg = "NONE" })
		vim.api.nvim_set_hl(0, "BufferLineSeparatorSelected", { fg = "NONE", bg = "NONE" })
		vim.api.nvim_set_hl(0, "BufferLineSeparatorVisible", { fg = "NONE", bg = "NONE" })
		vim.api.nvim_set_hl(0, "BufferLineOffsetSeparator", { fg = "NONE", bg = "NONE" })
		vim.api.nvim_set_hl(0, "TabLineFill", { bg = "NONE" })
		vim.api.nvim_set_hl(0, "TabLine", { bg = "NONE" })
		vim.api.nvim_set_hl(0, "CmpNormal", { bg = "NONE" })
		vim.api.nvim_set_hl(0, "CmpDocNormal", { bg = "NONE" })
		vim.api.nvim_set_hl(0, "CmpSelected", { bg = "#2a2a3a", bold = true })
		vim.api.nvim_set_hl(0, "CmpBorder", { fg = "#3a3a4a" })
	end,
}
