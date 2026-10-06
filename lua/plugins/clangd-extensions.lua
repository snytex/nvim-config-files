-- Extra clangd views: :ClangdAST, :ClangdTypeHierarchy, :ClangdSymbolInfo,
-- :ClangdMemoryUsage. Inlay hints come from Neovim itself (see lsp.lua).
return {
	"p00f/clangd_extensions.nvim",
	ft = { "c", "cpp", "objc", "objcpp", "cuda" },
	opts = {},
}
