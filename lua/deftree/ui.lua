local M = {}
local lsp = require("deftree.lsp")
local tree = require("deftree.tree")

-- State
local state = {
	bufnr = nil, -- deftree buffer
	win_id = nil, -- deftree window
	src_bufnr = nil, -- the main buffer which is being scanned
	symbols = nil, -- DOM tree
	items = {}, -- lines that is being rendered along with some metadata [!!IMPORTANT!!]: THIS SHOULD MAINTAIN LINE NUMBERS
}
---@param win integer|nil
function state.set_win(win)
	state.win_id = win
end
---@param buf integer|nil
function state.set_buf(buf)
	state.bufnr = buf
end
---@return boolean
function state.has_win()
	return state.win_id ~= nil and vim.api.nvim_win_is_valid(state.win_id)
end
---@return boolean
function state.has_buf()
	return state.bufnr ~= nil and vim.api.nvim_buf_is_valid(state.bufnr)
end

-- Window
local window = {
	---@type vim.api.keyset.win_config
	config = {
		relative = "win",
		height = vim.o.lines - 4,
		width = vim.o.columns - 4,
		row = math.floor((vim.o.lines - (vim.o.lines - 4)) / 2),
		col = math.floor((vim.o.columns - (vim.o.columns - 4)) / 2),
		title = "Deftree",
		title_pos = "center",
	},
	enter = true,
}

-- Namespace for highlights
local hl_ns = vim.api.nvim_create_namespace("deftree_highlights")

-- Helper functions
---@param buf integer
---@param lines string[]|nil
local function _set_buf_lines(buf, lines)
	lines = lines or {}

	vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
	vim.api.nvim_set_option_value("readonly", false, { buf = buf })

	if #lines == 0 then
		lines = { "<No Symbols Found>" }
	end
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	-- Clear existing highlights
	vim.api.nvim_buf_clear_namespace(buf, hl_ns, 0, -1)

	-- Apply highlights from state.items
	if state.items then
		for line_idx, item in ipairs(state.items) do
			if item.hl then
				for _, hl_group in ipairs(item.hl) do
					vim.api.nvim_buf_add_highlight(
						buf,
						hl_ns,
						hl_group.group,
						line_idx - 1, -- Convert to 0-indexed
						hl_group.start,
						hl_group["end"]
					)
				end
			end
		end
	end

	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
	vim.api.nvim_set_option_value("readonly", true, { buf = buf })
end

local function _add_separator()
	vim.list_extend( -- add empty line to maintain line numbers
		state.items,
		{ { text = "", hl = { start = 0, ["end"] = vim.o.columns - 4, group = "TabLineSel" } } }
	)
	return { string.rep("-", vim.o.columns - 4) }
end

local function _add_title(title)
	vim.list_extend(state.items, { -- adding to state items to maintain line numbers
		{
			text = title,
			hl = {
				{ start = 0, ["end"] = #title, group = "FloatTitle" },
			},
		},
		{ text = "", hl = {
			{ start = 0, ["end"] = #title, group = "FloatBorder" },
		} },
	})

	return {
		title,
		string.rep("=", #title),
	}
end

-- This function exposes buffer to other modules
---@return integer
function M.get_or_create_buf()
	if state.has_buf() then
		return state.bufnr
	end

	local buf = vim.api.nvim_create_buf(false, true)
	state.set_buf(buf)
	vim.api.nvim_set_option_value("bufhidden", "hide", { buf = buf })
	vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
	vim.api.nvim_set_option_value("swapfile", false, { buf = buf })
	vim.api.nvim_create_autocmd("BufWipeout", {
		buffer = buf,
		callback = function()
			state.set_buf(nil)
		end,
	})

	-- setup deftree specific keymaps
	require("deftree.keymaps").setup_keymaps(buf)
	return buf
end

-- Rendering stuff

function M.render()
	state.items = {} -- reset items
	local lines = _add_title("Table of Contents") -- add title
	lines = vim.list_extend(lines, M.render_toc()) -- add toc
	lines = vim.list_extend(lines, _add_separator()) -- add separator
	lines = vim.list_extend(lines, _add_title("Class Heirarchy")) -- add class heirarchy title
	lines = vim.list_extend(lines, M.render_class_heirarchy()) -- add class heirarchy
	lines = vim.list_extend(lines, _add_separator()) -- add separator
	lines = vim.list_extend(lines, _add_title("Function Heirarchy")) -- add function heirarchy title
	lines = vim.list_extend(lines, M.render_function_heirarchy()) -- add function heirarchy
	_set_buf_lines(state.bufnr, lines)
end

---@return string[]
function M.render_toc()
	if not state.has_buf() or not state.src_bufnr or not state.symbols then
		vim.notify("Deftree: No buffer or source buffer found", vim.log.levels.WARN)
		return {}
	end
	local tree_items = tree.generate_toc_tree(state.symbols)

	-- add tree items to state
	vim.list_extend(state.items, tree_items)

	-- return only text part of tree items
	return vim.tbl_map(function(l)
		return l.text
	end, tree_items)
end

---@return string[]
function M.render_class_heirarchy()
	if not state.has_buf() or not state.src_bufnr then
		vim.notify("Deftree: No buffer or source buffer found", vim.log.levels.WARN)
		return {}
	end

	-- this should also add to state.items
	return { "Not implemented yet" }
end

---@return string[]
function M.render_function_heirarchy()
	if not state.has_buf() or not state.src_bufnr then
		vim.notify("Deftree: No buffer or source buffer found", vim.log.levels.WARN)
		return {}
	end

	-- this should also add to state.items
	return { "Not implemented yet" }
end

-- Window management
function M.open_window()
	if state.has_win() then
		vim.api.nvim_set_current_win(state.win_id)
		return
	end
	state.src_bufnr = vim.api.nvim_get_current_buf()
	state.symbols = lsp.get_toc(state.src_bufnr) -- caching this so the i dont call lsp every time i render but i have to call it when i open the window to keep it updated

	local buf = M.get_or_create_buf()
	state.set_win(vim.api.nvim_open_win(buf, window.enter, window.config))

	-- if window is closed manually
	vim.api.nvim_create_autocmd("WinClosed", {
		buffer = buf,
		callback = function()
			state.win_id = nil
		end,
	})
	M.render()
end

function M.close_window()
	if state.has_win() then
		vim.api.nvim_win_close(state.win_id, true)
		state.set_win(nil)
	end
end

function M.toggle_window(_)
	if state.has_win() then
		M.close_window()
	else
		M.open_window()
	end
end

-- Tree interactions
function M.toggle_node(line_number)
	local line = state.items and state.items[line_number]
	if not line or not line.data then
		return
	end
	line.data.expanded = not line.data.expanded
	M.render()
end

function M.refresh()
	if not state.src_bufnr then
		return
	end
	state.symbols = lsp.get_toc(state.src_bufnr)
	M.render()
end

return M
