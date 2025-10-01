local M = {}
local lsp = require("deftree.lsp")
local tree = require("deftree.tree")

-- State
local state = {
	bufnr = nil, -- deftree buffer
	win_id = nil, -- deftree window
	symbols = nil, -- DOM tree
	lines = nil, -- lines that is being rendered (used to toggle nodes)
	src_bufnr = nil, -- the main buffer which is being scanned
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

---@param buf integer
---@param lines TreeItem[]|nil
local function _set_buf_lines(buf, lines)
	lines = lines or {}

	vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
	vim.api.nvim_set_option_value("readonly", false, { buf = buf })

	local text = vim.tbl_map(function(l)
		return l.text
	end, lines)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, text)

	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
	vim.api.nvim_set_option_value("readonly", true, { buf = buf })
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

	return buf
end

function M.render()
	if not state.has_buf() or not state.src_bufnr or not state.symbols then
		vim.notify("Deftree: No buffer or source buffer found", vim.log.levels.WARN)
		return
	end
	state.lines = tree.generate_toc_tree(state.symbols)
	_set_buf_lines(state.bufnr, state.lines)

	--TODO: set highlights
end

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

function M.toggle_node(line_number)
	local line = state.lines and state.lines[line_number]
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
