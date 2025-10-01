local M = {}

function M.setup(opts)
	opts = opts or {}
	vim.api.nvim_create_user_command("DeftreeToggle", require("deftree.ui").toggle_window, {})
end

return M
