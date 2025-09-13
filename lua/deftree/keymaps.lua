-- Sets deftree specific keybinds
local M = {}

function M.setup_keymaps()
	local ui = require("deftree.ui")

	-- quit deftree
	vim.api.nvim_buf_set_keymap(
		ui.get_or_create_buf(),
		"n",
		"q",
		"",
		{ noremap = true, silent = true, callback = ui.close_window }
	)
	return true
end

return M
