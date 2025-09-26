local M = {}

-- State
local state = {
	bufnr = nil,
	win_id = nil,
}
---@param win integer|nil
function state.set_win(win)
	state.win_id = win
end
---@param buf integer|nil
function state.set_buf(buf)
	state.bufnr = buf
end
---@return boolean|nil
function state.has_win()
	return state.win_id and vim.api.nvim_win_is_valid(state.win_id)
end
---@return boolean|nil
function state.has_buf()
	return state.bufnr and vim.api.nvim_buf_is_valid(state.bufnr)
end

-- Window
local window = {
	---@type vim.api.keyset.win_config
	config = {
		relative = "win",
		height = vim.o.lines - 4,
		width = vim.o.columns - 4,
		row = 0,
		col = 0,
		title = "Deftree",
		title_pos = "center",
	},
	enter = true,
}

-- This function exposes buffer to other modules
---@return integer
function M.get_or_create_buf()
	if state.has_buf() then
		return state.bufnr
	end

	state.set_buf(vim.api.nvim_create_buf(false, true))
	vim.api.nvim_set_option_value("bufhidden", "hide", { buf = state.bufnr })
	return state.bufnr
end

function M.open_window()
	if state.has_win() then
		vim.api.nvim_set_current_win(state.win_id)
		return
	end
	state.set_win(vim.api.nvim_open_win(M.get_or_create_buf(), window.enter, window.config))
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

return M
