-- Sets deftree specific keybinds
local M = {}

function M.setup_keymaps()
	local ui = require("deftree.ui")
	local buf = ui.get_or_create_buf()

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
