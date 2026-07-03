local M = {}

local function escape_line(line)
	line = line:gsub("\\", "\\\\")
	line = line:gsub('"', '\\"')
	return line
end

local function get_visual_lines()
	local s = vim.fn.line("'<")
	local e = vim.fn.line("'>")
	return vim.api.nvim_buf_get_lines(0, s - 1, e, false), s, e
end

function M.convert()
	local lines, s, e = get_visual_lines()
	if #lines == 0 then
		return
	end

	local name = vim.fn.input("Variable name [ascii_art]: ")
	if name == "" then
		name = "ascii_art"
	end

	local out = { "std::vector<std::string> " .. name .. " = {" }
	for i, line in ipairs(lines) do
		local comma = i < #lines and "," or ""
		table.insert(out, '    "' .. escape_line(line) .. '"' .. comma)
	end
	table.insert(out, "};")

	vim.api.nvim_buf_set_lines(0, s - 1, e, false, out)
end

return M
