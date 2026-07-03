local M = {}

local COLORS = {
	{ name = "none (skip)", code = nil },
	{ name = "black", code = "\\033[30m" },
	{ name = "red", code = "\\033[31m" },
	{ name = "green", code = "\\033[32m" },
	{ name = "yellow", code = "\\033[33m" },
	{ name = "blue", code = "\\033[34m" },
	{ name = "magenta", code = "\\033[35m" },
	{ name = "cyan", code = "\\033[36m" },
	{ name = "white", code = "\\033[37m" },
	{ name = "bright red", code = "\\033[91m" },
	{ name = "bright green", code = "\\033[92m" },
	{ name = "bright yellow", code = "\\033[93m" },
	{ name = "bright blue", code = "\\033[94m" },
	{ name = "bright magenta", code = "\\033[95m" },
	{ name = "bright cyan", code = "\\033[96m" },
	{ name = "bright white", code = "\\033[97m" },
}

local RESET = "\\033[0m"

local function utf8_chars(line)
	local chars = {}
	local i = 1
	while i <= #line do
		local b = line:byte(i)
		local len = b < 0x80 and 1 or b < 0xE0 and 2 or b < 0xF0 and 3 or 4
		table.insert(chars, line:sub(i, i + len - 1))
		i = i + len
	end
	return chars
end

-- Extract the content between the first pair of " " on a line
local function extract_string_content(line)
	local content = line:match('^%s*"(.*)"[,]?%s*$')
	return content
end

local function unique_chars(contents)
	local seen, order = {}, {}
	for _, content in ipairs(contents) do
		for _, ch in ipairs(utf8_chars(content)) do
			if ch ~= " " and not seen[ch] then
				seen[ch] = true
				table.insert(order, ch)
			end
		end
	end
	return order
end

local function pick_color(char)
	local menu = { string.format("  Color for '%s':", char) }
	for i, c in ipairs(COLORS) do
		table.insert(menu, string.format("  %2d.  %s", i, c.name))
	end
	local choice = vim.fn.inputlist(menu)
	if choice < 1 or choice > #COLORS then
		return nil
	end
	return COLORS[choice].code
end

local function escape_char(c)
	if c == "\\" then
		return "\\\\"
	end
	if c == '"' then
		return '\\"'
	end
	return c
end

local function colorize_content(content, assignments)
	local out, current = "", nil
	for _, ch in ipairs(utf8_chars(content)) do
		local color = assignments[ch]
		if color ~= current then
			out = out .. (color and color or RESET)
			current = color
		end
		out = out .. escape_char(ch)
	end
	if current then
		out = out .. RESET
	end
	return out
end

function M.convert()
	local s = vim.fn.line("'<")
	local e = vim.fn.line("'>")
	local lines = vim.api.nvim_buf_get_lines(0, s - 1, e, false)
	if #lines == 0 then
		return
	end

	-- Extract string contents from vector lines, skip non-string lines
	local contents = {}
	local line_has_string = {}
	for i, line in ipairs(lines) do
		local content = extract_string_content(line)
		if content then
			table.insert(contents, content)
			line_has_string[i] = content
		end
	end

	if #contents == 0 then
		vim.notify("[ascii-color] No quoted strings found in selection. Select the vector lines.", vim.log.levels.WARN)
		return
	end

	-- Find unique chars across all string contents
	local chars = unique_chars(contents)
	if #chars == 0 then
		vim.notify("[ascii-color] No non-space characters found.", vim.log.levels.WARN)
		return
	end

	-- Pick colors
	local assignments = {}
	for _, ch in ipairs(chars) do
		assignments[ch] = pick_color(ch)
	end

	-- Rewrite only the lines that had strings
	local result = {}
	for i, line in ipairs(lines) do
		if line_has_string[i] then
			local colored = colorize_content(line_has_string[i], assignments)
			local indent = line:match("^(%s*)")
			local comma = line:match(",[%s]*$") and "," or ""
			table.insert(result, indent .. '"' .. colored .. '"' .. comma)
		else
			table.insert(result, line) -- keep { }; lines untouched
		end
	end

	vim.api.nvim_buf_set_lines(0, s - 1, e, false, result)
	vim.notify(string.format("[ascii-color] Colorized %d strings.", #contents), vim.log.levels.INFO)
end

return M
