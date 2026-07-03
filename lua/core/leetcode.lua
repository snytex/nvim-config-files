local M = {}

-- ─── helpers ──────────────────────────────────────────────────────────────────

local difficulty_map = { easy = 1, medium = 2, hard = 3 }

--- Strip HTML tags and decode common HTML entities into plain text.
local function html_to_text(html)
	local t = html
	t = t:gsub("<br%s*/?>", "\n")
	t = t:gsub("</?p>", "\n")
	t = t:gsub("</?div[^>]*>", "\n")
	t = t:gsub("</?li>", "\n")
	t = t:gsub("</?[uо]l[^>]*>", "\n")
	t = t:gsub("</?pre[^>]*>", "\n")
	t = t:gsub("<[^>]+>", "")
	t = t:gsub("&lt;", "<")
	t = t:gsub("&gt;", ">")
	t = t:gsub("&amp;", "&")
	t = t:gsub("&quot;", '"')
	t = t:gsub("&#39;", "'")
	t = t:gsub("&nbsp;", " ")
	t = t:gsub("\n\n\n+", "\n\n")
	return t:match("^%s*(.-)%s*$")
end

--- Wrap plain text into // comment lines with word-wrap at `width` chars.
local function to_comment_lines(title, difficulty_label, plain)
	local width = 78
	local sep = string.rep("-", width)
	local lines = {}

	table.insert(lines, "// " .. sep)
	table.insert(lines, "// " .. title .. "  [" .. difficulty_label .. "]")
	table.insert(lines, "// " .. sep)

	for _, raw in ipairs(vim.split(plain, "\n")) do
		local line = raw:match("^%s*(.-)%s*$")
		if line == "" then
			table.insert(lines, "//")
		else
			while #line > width do
				local cut = width
				while cut > 1 and line:sub(cut, cut) ~= " " do
					cut = cut - 1
				end
				if cut == 1 then
					cut = width
				end
				table.insert(lines, "// " .. line:sub(1, cut))
				line = line:sub(cut + 1):match("^%s*(.-)%s*$")
			end
			if line ~= "" then
				table.insert(lines, "// " .. line)
			end
		end
	end

	table.insert(lines, "// " .. sep)
	return lines
end

--- Rename the current buffer's file to `{num}.{ext}`, keeping the same dir.
--- Reloads the buffer under the new name.
local function rename_buf_to_num(num)
	local old_path = vim.api.nvim_buf_get_name(0)
	if old_path == "" then
		vim.notify("leetcode: buffer has no file name, skipping rename", vim.log.levels.WARN)
		return
	end
	local dir = vim.fn.fnamemodify(old_path, ":h")
	local ext = vim.fn.fnamemodify(old_path, ":e")
	local new_name = tostring(num) .. (ext ~= "" and ("." .. ext) or "")
	local new_path = dir .. "/" .. new_name

	local ok = vim.fn.rename(old_path, new_path)
	if ok ~= 0 then
		vim.notify("leetcode: rename failed (" .. old_path .. " → " .. new_path .. ")", vim.log.levels.ERROR)
		return
	end

	-- Point the buffer at the new path and keep it in sync
	vim.api.nvim_buf_set_name(0, new_path)
	vim.cmd("silent! edit") -- refresh so &filename etc. update
	vim.notify("leetcode: renamed to " .. new_name, vim.log.levels.INFO)
end

-- ─── network ─────────────────────────────────────────────────────────────────

local function curl_post_graphql(query_str, variables, callback)
	local payload = vim.fn.json_encode({ query = query_str, variables = variables })
	local chunks = {}
	vim.fn.jobstart({
		"curl",
		"-s",
		"--max-time",
		"15",
		"-X",
		"POST",
		"-H",
		"Content-Type: application/json",
		"-H",
		"User-Agent: Mozilla/5.0 (X11; Linux x86_64)",
		"-H",
		"Referer: https://leetcode.com",
		"--data",
		payload,
		"https://leetcode.com/graphql",
	}, {
		stdout_buffered = true,
		on_stdout = function(_, data)
			if data then
				vim.list_extend(chunks, data)
			end
		end,
		on_exit = function(_, code)
			if code ~= 0 then
				return callback(nil, "network error (curl exit " .. code .. ")")
			end
			local ok, decoded = pcall(vim.fn.json_decode, table.concat(chunks, ""))
			if not ok then
				return callback(nil, "failed to parse GraphQL response")
			end
			callback(decoded)
		end,
	})
end

local function fetch_all_problems(callback)
	local chunks = {}
	vim.fn.jobstart({
		"curl",
		"-s",
		"--max-time",
		"20",
		"-H",
		"User-Agent: Mozilla/5.0 (X11; Linux x86_64)",
		"https://leetcode.com/api/problems/all/",
	}, {
		stdout_buffered = true,
		on_stdout = function(_, data)
			if data then
				vim.list_extend(chunks, data)
			end
		end,
		on_exit = function(_, code)
			if code ~= 0 then
				return callback(nil, "network error (curl exit " .. code .. ")")
			end
			local ok, decoded = pcall(vim.fn.json_decode, table.concat(chunks, ""))
			if not ok or not decoded or not decoded.stat_status_pairs then
				return callback(nil, "failed to parse problem list")
			end
			callback(decoded.stat_status_pairs)
		end,
	})
end

-- ─── lookups ──────────────────────────────────────────────────────────────────

--- callback(slug, err)
local function fetch_slug(num, callback)
	fetch_all_problems(function(pairs, err)
		if err then
			return callback(nil, err)
		end
		for _, pair in ipairs(pairs) do
			if pair.stat and pair.stat.frontend_question_id == tonumber(num) then
				return callback(pair.stat.question__title_slug)
			end
		end
		callback(nil, "problem #" .. num .. " not found")
	end)
end

--- callback({ slug, num }, err)  — returns both so the caller can rename.
local function fetch_random(difficulty_level, callback)
	fetch_all_problems(function(pairs, err)
		if err then
			return callback(nil, err)
		end
		local pool = {}
		for _, pair in ipairs(pairs) do
			if pair.difficulty and pair.difficulty.level == difficulty_level and not pair.paid_only and pair.stat then
				table.insert(pool, {
					slug = pair.stat.question__title_slug,
					num = pair.stat.frontend_question_id,
				})
			end
		end
		if #pool == 0 then
			return callback(nil, "no free problems found for that difficulty")
		end
		math.randomseed(os.time())
		callback(pool[math.random(#pool)])
	end)
end

--- callback(code, err)
local function fetch_snippet(slug, callback)
	curl_post_graphql(
		"query questionEditorData($titleSlug: String!) { question(titleSlug: $titleSlug) { codeSnippets { langSlug code } } }",
		{ titleSlug = slug },
		function(decoded, err)
			if err then
				return callback(nil, err)
			end
			local snippets = decoded.data and decoded.data.question and decoded.data.question.codeSnippets
			if not snippets then
				return callback(nil, "no snippets in response")
			end
			for _, s in ipairs(snippets) do
				if s.langSlug == "cpp" then
					return callback(s.code)
				end
			end
			callback(nil, "no C++ snippet found for " .. slug)
		end
	)
end

--- callback({ title, difficulty, content }, err)
local function fetch_description(slug, callback)
	curl_post_graphql(
		[[query questionContent($titleSlug: String!) {
			question(titleSlug: $titleSlug) { title difficulty content }
		}]],
		{ titleSlug = slug },
		function(decoded, err)
			if err then
				return callback(nil, err)
			end
			local q = decoded.data and decoded.data.question
			if not q then
				return callback(nil, "no question data in response")
			end
			callback({ title = q.title or slug, difficulty = q.difficulty or "?", content = q.content or "" })
		end
	)
end

-- ─── core insert ─────────────────────────────────────────────────────────────

--- Fetch description + snippet in parallel, then write into the buffer.
--- `num` is only used for the rename; pass nil to skip.
local function insert_problem(bufnr, row, slug, num, do_rename)
	local desc_result, desc_err, snippet_result, snippet_err
	local done = 0

	local function try_assemble()
		done = done + 1
		if done < 2 then
			return
		end

		vim.schedule(function()
			if desc_err then
				vim.notify("leetcode: description unavailable: " .. desc_err, vim.log.levels.WARN)
			end
			if snippet_err then
				vim.api.nvim_buf_set_lines(bufnr, row, row + 1, false, { "// Error: " .. snippet_err })
				return
			end

			local lines = {}

			if desc_result then
				local plain = html_to_text(desc_result.content)
				local comment_lines = to_comment_lines(desc_result.title, desc_result.difficulty, plain)
				vim.list_extend(lines, comment_lines)
				table.insert(lines, "")
			end

			table.insert(lines, "#include <bits/stdc++.h>")
			table.insert(lines, "using namespace std;")
			table.insert(lines, "")

			for _, l in ipairs(vim.split(snippet_result, "\n")) do
				table.insert(lines, l)
			end

			vim.api.nvim_buf_set_lines(bufnr, row, row + 1, false, lines)
			vim.api.nvim_win_set_cursor(0, { row + #lines, 0 })

			if do_rename and num then
				rename_buf_to_num(num)
			end
		end)
	end

	fetch_description(slug, function(r, e)
		desc_result, desc_err = r, e
		try_assemble()
	end)
	fetch_snippet(slug, function(r, e)
		snippet_result, snippet_err = r, e
		try_assemble()
	end)
end

-- ─── :Lc command ─────────────────────────────────────────────────────────────
--
--   :Lc <number>              specific problem
--   :Lc easy|medium|hard      random by difficulty
--   append -r to any form     also rename current file to <number>.<ext>

vim.api.nvim_create_user_command("Lc", function(opts)
	-- Split raw args, strip -r flag
	local args_raw = vim.split(opts.args, "%s+", { trimempty = true })
	local do_rename = false
	local args = {}
	for _, a in ipairs(args_raw) do
		if a == "-r" then
			do_rename = true
		else
			table.insert(args, a)
		end
	end

	if #args == 0 then
		vim.notify("Usage: :Lc <number>|-r  |  :Lc easy|medium|hard [-r]", vim.log.levels.ERROR)
		return
	end

	local target = args[1]
	local bufnr = vim.api.nvim_get_current_buf()
	local row = vim.api.nvim_win_get_cursor(0)[1] - 1

	local level = difficulty_map[target:lower()]

	if level then
		-- ── random by difficulty ──────────────────────────────────────────
		local label = target:sub(1, 1):upper() .. target:sub(2):lower()
		vim.api.nvim_buf_set_lines(
			bufnr,
			row,
			row + 1,
			false,
			{ "// Fetching random " .. label .. " LeetCode problem..." }
		)

		fetch_random(level, function(info, err)
			if err then
				vim.schedule(function()
					vim.api.nvim_buf_set_lines(bufnr, row, row + 1, false, { "// Error: " .. err })
				end)
				return
			end
			insert_problem(bufnr, row, info.slug, info.num, do_rename)
		end)
	elseif tonumber(target) then
		-- ── specific number ───────────────────────────────────────────────
		local num = tonumber(target)
		vim.api.nvim_buf_set_lines(bufnr, row, row + 1, false, { "// Fetching LeetCode #" .. num .. "..." })

		fetch_slug(num, function(slug, err)
			if err then
				vim.schedule(function()
					vim.api.nvim_buf_set_lines(bufnr, row, row + 1, false, { "// Error: " .. err })
				end)
				return
			end
			insert_problem(bufnr, row, slug, num, do_rename)
		end)
	else
		vim.notify('leetcode: unrecognised argument "' .. target .. '"', vim.log.levels.ERROR)
	end
end, {
	nargs = "+",
	complete = function(lead)
		local candidates = { "easy", "medium", "hard", "-r" }
		local out = {}
		for _, c in ipairs(candidates) do
			if c:sub(1, #lead) == lead then
				table.insert(out, c)
			end
		end
		return out
	end,
	desc = "Fetch a LeetCode problem  [:Lc <num>|easy|medium|hard [-r]]",
})

return M
