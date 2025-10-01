-- Sets deftree specific keybinds
local M = {}

---@param buf integer
function M.setup_keymaps(buf)
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	local ui = require("deftree.ui")

	-- quit deftree
	vim.api.nvim_buf_set_keymap(buf, "n", "q", "", { noremap = true, silent = true, callback = ui.close_window })

	-- refresh deftree
	vim.api.nvim_buf_set_keymap(buf, "n", "r", "", { noremap = true, silent = true, callback = ui.refresh })

	-- toggle node
	vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", "", {
		noremap = true,
		silent = true,
		callback = function()
			local cursor = vim.api.nvim_win_get_cursor(0)
			ui.toggle_node(cursor[1])
		end,
	})
end

return M
