-- Obsidian Cherry: syntax-only highlight overlay (UI stays from the base colorscheme)
local M = {}

local c = {
	purple = "#a77bf0", -- types, structs, classes, templates
	purple_deep = "#8466d6", -- builtin types (int, float, ...)
	purple_mute = "#7d6fa6", -- namespaces / prefixes
	cherry = "#e2455f", -- keywords, directives
		rose = "#e895a8", -- fields / properties
	plum = "#c95fae", -- variables
	plum_soft = "#dc8fca", -- parameters
	periwinkle = "#a9b1ff", -- functions / methods
	peach = "#f2b48c", -- strings
	coral = "#ff8f6b", -- numbers, constants, enum members
	orchid = "#d17ad8", -- macros / preprocessor
	dusk = "#8a809e", -- operators / punctuation
	comment = "#5f5673", -- comments
}

local hl = {
	-- legacy groups
	Comment = { fg = c.comment, italic = true },
	String = { fg = c.peach },
	Character = { fg = c.coral },
	Number = { fg = c.coral },
	Float = { fg = c.coral },
	Boolean = { fg = c.coral, italic = true },
	Constant = { fg = c.coral },
	Identifier = { fg = c.plum },
	Function = { fg = c.periwinkle },
	Statement = { fg = c.cherry },
	Keyword = { fg = c.cherry, italic = true },
	Conditional = { fg = c.cherry, italic = true },
	Repeat = { fg = c.cherry, italic = true },
	Exception = { fg = c.cherry, italic = true },
	Operator = { fg = c.dusk },
	PreProc = { fg = c.cherry },
	Include = { fg = c.cherry },
	Define = { fg = c.cherry },
	Macro = { fg = c.orchid },
	Type = { fg = c.purple },
	StorageClass = { fg = c.cherry },
	Structure = { fg = c.purple },
	Typedef = { fg = c.purple },
	Special = { fg = c.rose },
	Delimiter = { fg = c.dusk },

	-- vim regex syntax (used when no treesitter parser is active)
	cIncluded = { fg = c.purple_mute }, -- <iostream>, "foo.h"
	cDefine = { fg = c.cherry }, -- #define, #undef
	cPreCondit = { fg = c.cherry }, -- #ifdef, #endif

	-- treesitter
	["@variable"] = { fg = c.plum },
	["@variable.builtin"] = { fg = c.plum, italic = true }, -- this, self
	["@variable.parameter"] = { fg = c.plum_soft, italic = true },
	["@variable.member"] = { fg = c.rose },
	["@property"] = { fg = c.rose },
	["@constant"] = { fg = c.coral },
	["@constant.builtin"] = { fg = c.coral, italic = true },
	["@constant.macro"] = { fg = c.orchid },
	["@module"] = { fg = c.purple_mute, italic = true },
	["@module.builtin"] = { fg = c.purple_mute, italic = true },
	["@label"] = { fg = c.purple_mute },
	["@string"] = { fg = c.peach },
	["@string.escape"] = { fg = c.coral, bold = true },
	["@string.special"] = { fg = c.coral },
	["@string.special.path"] = { fg = c.purple_mute },
	["@character"] = { fg = c.coral },
	["@number"] = { fg = c.coral },
	["@number.float"] = { fg = c.coral },
	["@boolean"] = { fg = c.coral, italic = true },
	["@type"] = { fg = c.purple },
	["@type.builtin"] = { fg = c.purple_deep, italic = true },
	["@type.definition"] = { fg = c.purple },
	["@type.qualifier"] = { fg = c.cherry, italic = true },
	["@attribute"] = { fg = c.orchid },
	["@function"] = { fg = c.periwinkle },
	["@function.builtin"] = { fg = c.periwinkle, italic = true },
	["@function.call"] = { fg = c.periwinkle },
	["@function.macro"] = { fg = c.orchid },
	["@function.method"] = { fg = c.periwinkle },
	["@function.method.call"] = { fg = c.periwinkle },
	["@constructor"] = { fg = c.purple },
	["@operator"] = { fg = c.dusk },
	["@keyword"] = { fg = c.cherry, italic = true },
	["@keyword.function"] = { fg = c.cherry, italic = true },
	["@keyword.operator"] = { fg = c.cherry, italic = true },
	["@keyword.return"] = { fg = c.cherry, italic = true },
	["@keyword.import"] = { fg = c.cherry },
	["@keyword.directive"] = { fg = c.cherry },
	["@keyword.directive.define"] = { fg = c.cherry },
	["@keyword.modifier"] = { fg = c.cherry, italic = true },
	["@keyword.type"] = { fg = c.cherry, italic = true },
	["@keyword.conditional"] = { fg = c.cherry, italic = true },
	["@keyword.repeat"] = { fg = c.cherry, italic = true },
	["@keyword.exception"] = { fg = c.cherry, italic = true },
	["@punctuation.delimiter"] = { fg = c.dusk },
	["@punctuation.bracket"] = { fg = c.dusk },
	["@punctuation.special"] = { fg = c.orchid },
	["@comment"] = { fg = c.comment, italic = true },
	["@tag"] = { fg = c.purple },
	["@tag.attribute"] = { fg = c.rose },
	["@tag.delimiter"] = { fg = c.dusk },

	-- LSP semantic tokens (override treesitter where the server knows better)
	["@lsp.type.class"] = { fg = c.purple },
	["@lsp.type.struct"] = { fg = c.purple },
	["@lsp.type.enum"] = { fg = c.purple },
	["@lsp.type.interface"] = { fg = c.purple },
	["@lsp.type.concept"] = { fg = c.purple, italic = true },
	["@lsp.type.type"] = { fg = c.purple },
	["@lsp.type.typeParameter"] = { fg = c.purple, italic = true }, -- template params
	["@lsp.type.templateParameter"] = { fg = c.purple, italic = true },
	["@lsp.type.namespace"] = { fg = c.purple_mute, italic = true },
	["@lsp.type.variable"] = { fg = c.plum },
	["@lsp.type.parameter"] = { fg = c.plum_soft, italic = true },
	["@lsp.type.property"] = { fg = c.rose },
	["@lsp.type.enumMember"] = { fg = c.coral },
	["@lsp.type.function"] = { fg = c.periwinkle },
	["@lsp.type.method"] = { fg = c.periwinkle },
	["@lsp.type.macro"] = { fg = c.orchid },
	["@lsp.type.keyword"] = { fg = c.cherry, italic = true },
	["@lsp.type.comment"] = {},
	["@lsp.typemod.variable.defaultLibrary"] = { fg = c.plum, italic = true },
}

function M.apply()
	for group, spec in pairs(hl) do
		vim.api.nvim_set_hl(0, group, spec)
	end
end

function M.setup()
	M.apply()
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = vim.api.nvim_create_augroup("ObsidianSyntax", { clear = true }),
		callback = M.apply,
	})
end

return M
