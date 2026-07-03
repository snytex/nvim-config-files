-- Auto-append `;` after the closing brace of C/C++ type definitions.
--
-- When nvim-autopairs completes a brace pair for a class/struct/union/enum
-- (e.g. typing `class Application {` produces `class Application {}`), this
-- turns it into `class Application {};` automatically, so you never have to
-- reach over and add the trailing semicolon yourself. If you then delete the
-- brace pair again, the semicolon we added is removed with it.
--
-- It is treesitter-driven, so it only fires for the constructs that actually
-- require a semicolon. Function bodies, control-flow blocks, brace
-- initializers and lambdas are left alone. Namespaces are intentionally
-- excluded too: `namespace ns {}` does NOT take a trailing `;` in C++ (and
-- adding one trips `-Wextra-semi`/`-Wpedantic`).

local M = {}

-- Namespace for extmarks tracking every `;` we insert, so we can remove them
-- again if their braces are deleted (without touching semicolons you typed).
local ns = vim.api.nvim_create_namespace("CppAutoSemicolon")

-- Treesitter node types whose `{ ... }` body must be terminated with `;`.
local NEEDS_SEMI = {
	class_specifier = true,
	struct_specifier = true,
	union_specifier = true,
	enum_specifier = true,
}

local function get_line(bufnr, row)
	return vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
end

-- The character immediately before (row, col), looking onto the previous line
-- if we're at the start of a line.
local function char_before(bufnr, row, col)
	if col > 0 then
		return get_line(bufnr, row):sub(col, col)
	elseif row > 0 then
		return get_line(bufnr, row - 1):sub(-1)
	end
	return ""
end

-- Remove any semicolon we previously inserted whose closing `}` has since been
-- deleted, and stop tracking semicolons you've edited away yourself.
local function cleanup_orphaned_semis(bufnr)
	for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, {})) do
		local id, row, col = mark[1], mark[2], mark[3]
		local here = get_line(bufnr, row):sub(col + 1, col + 1)
		if here ~= ";" then
			-- Not our semicolon anymore; forget it.
			vim.api.nvim_buf_del_extmark(bufnr, ns, id)
		elseif char_before(bufnr, row, col) ~= "}" then
			-- The brace pair this `;` terminated is gone; take the `;` with it.
			vim.api.nvim_buf_del_extmark(bufnr, ns, id)
			vim.api.nvim_buf_set_text(bufnr, row, col, row, col + 1, {})
		end
	end
end

local function maybe_add_semicolon(bufnr)
	local row, col = unpack(vim.api.nvim_win_get_cursor(0)) -- row: 1-indexed, col: 0-indexed byte
	local line = vim.api.nvim_get_current_line()

	-- Cheap gate first: the cursor must be sitting inside a freshly completed,
	-- empty brace pair `{|}`. This is exactly the state autopairs leaves us in.
	if line:sub(col, col) ~= "{" or line:sub(col + 1, col + 1) ~= "}" then
		return
	end
	-- Already terminated? Bail. (Also stops the insertion below from
	-- re-triggering this handler in an endless loop.)
	if line:sub(col + 2, col + 2) == ";" then
		return
	end

	-- Make sure the tree reflects the character we just typed, then ask what
	-- owns these braces.
	local ok_parser, parser = pcall(vim.treesitter.get_parser, bufnr)
	if not ok_parser or not parser then
		return
	end
	pcall(parser.parse, parser, { row - 1, row })

	local ok_node, node = pcall(vim.treesitter.get_node, {
		bufnr = bufnr,
		pos = { row - 1, col - 1 }, -- on the opening `{`
	})
	if not ok_node or not node then
		return
	end

	local parent = node:parent()
	if not parent or not NEEDS_SEMI[parent:type()] then
		return
	end

	-- Insert `;` right after the closing `}` without moving the cursor, and
	-- track it so we can undo it if the braces are later removed.
	vim.api.nvim_buf_set_text(bufnr, row - 1, col + 1, row - 1, col + 1, { ";" })
	vim.api.nvim_buf_set_extmark(bufnr, ns, row - 1, col + 1, { right_gravity = false })
end

local function on_change()
	local bufnr = vim.api.nvim_get_current_buf()
	cleanup_orphaned_semis(bufnr)
	maybe_add_semicolon(bufnr)
end

function M.setup()
	local group = vim.api.nvim_create_augroup("CppAutoSemicolon", { clear = true })
	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		pattern = { "c", "cpp" },
		callback = function(args)
			-- Attach a buffer-local handler so the treesitter work only runs in
			-- C/C++ buffers. Clear first to avoid duplicates on buffer reload.
			vim.api.nvim_clear_autocmds({ event = "TextChangedI", buffer = args.buf, group = group })
			vim.api.nvim_create_autocmd("TextChangedI", {
				group = group,
				buffer = args.buf,
				callback = on_change,
			})
		end,
	})
end

return M
